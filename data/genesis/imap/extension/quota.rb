#!/bin/env/ruby
#
# = data/imap/extension/quota.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# IMAP Extension namespace test cases
#
if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"
require "action/block"

require "action/decorator"
require "action/zmprov"
require "action/proxy"
require "action/sendmail"
require "action/verify"
require "net/imap"; require "action/imap" #Patch Net::IMAP library

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP Quota test"

name = 'iext'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
#name = "admin" if ($0 == __FILE__)
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)


mimap = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true) 
include Action

 
#
# Setup
#
current.setup = [
  
]
message = <<EOF.gsub(/\n/, "\r\n")
Subject: hello
From: genesis@test.org
To: genesis@ruby-lang.org

hello world
EOF

def DupResponse(responses)
  rhash = responses.dup
  responses.each do |key, value|
    rhash[key] = value.dup
  end
  rhash
end
#
#
# Execution
#
current.action = [      
  CreateAccount.new(testAccount.name,testAccount.password),
  p(mimap.method('send_command'),'login',testAccount.name, testAccount.password, testAccount.name),  
  p(mimap.method('login'),testAccount.name,testAccount.password),  
  p(mimap.method('create'),"INBOX/quota"),    
  decorator(p(mimap.method('append'),"INBOX/quota", message+"line\r\n"*100000, [:Answered, :Deleted, :Draft, :Flagged, :Seen], Time.now), Decorator::NODUMP),
  
  v(cb("Quota INBOX Root") do 
    mimap.method('send_command').call('GETQUOTAROOT INBOX')
    IMAP.dupResponse(mimap.responses) 
  end) do |mcaller, data| 
    mcaller.pass = (data.class == Hash) && data.has_key?('QUOTAROOT') &&
      (data['QUOTAROOT'].size > 0) &&
      (data['QUOTAROOT'][0].quotaroots == [])
  end, 
  
  v(cb('Get Quota ""') do
    mimap.method('send_command').call('GETQUOTA ""')
    IMAP.dupResponse(mimap.responses) 
  end, &IMAP::GetQuotaFailed),
    
  v(cb('Set Quota""') do
    mimap.method('send_command').call('SETQUOTA "" (STORAGE 512)')
    IMAP.dupResponse(mimap.responses) 
  end, &IMAP::SetQuotaFailed),
  
  v(cb('Set Quota INBOX') do
      mimap.method('send_command').call('SETQUOTA INBOX (STORAGE 512)')
      IMAP.dupResponse(mimap.responses) 
  end, &IMAP::SetQuotaFailed),
   
  # Some negative test cases
#  cb("Quota Invisible Folders") { 
#    mresponse = []
#    ['Contacts', 'Calendar', "Nohere"].each { |i|
#      mresponse = mresponse << i << mimap.method('send_command').call("GETQUOTAROOT #{i}") << mimap.responses
#    }
#    mresponse
#  }, 
  ['Calendar', "Nohere"].map do |x|
    v(cb("Getquota on #{x}") do
      mimap.method('send_command').call("GETQUOTAROOT #{x}")
      IMAP.dupResponse(mimap.responses)
    end, &IMAP::GetQuotaRootFailed)  
  end,
  
  ['Drafts', 'Junk', "Trash"].map do |x|
    v(cb("Getquota on #{x}") do
      mimap.method('send_command').call("GETQUOTAROOT #{x}")
      IMAP.dupResponse(mimap.responses)
    end) do |mcaller, data|
      mcaller.pass = data.class == Hash && data.has_key?('QUOTAROOT') &&
                     data['QUOTAROOT'].size > 0 &&
                     data['QUOTAROOT'][-1].quotaroots == [] &&
                     data['QUOTAROOT'][-1].mailbox.upcase == x.upcase 
    end
  end,
    
  ['FALSE', 'TRUE'].map do |x|
  [
    ZMProv.new('mcf', 'zimbraImapDisplayMailFoldersOnly', x),
      
    v(cb("Getquota Contacts when zimbraImapDisplayMailFoldersOnly is #{x}") do
      mimap.method('send_command').call("GETQUOTAROOT Contacts")
      IMAP.dupResponse(mimap.responses)
    end) do |mcaller, data|
      mcaller.pass = x == 'FALSE' && data.class == Hash && data.has_key?('QUOTAROOT') &&
                     data['QUOTAROOT'].size > 0 &&
                     data['QUOTAROOT'][-1].quotaroots == [] &&
                     data['QUOTAROOT'][-1].mailbox.upcase == 'CONTACTS' ||
                     x == 'TRUE' && data.class == Net::IMAP::NoResponseError &&
                     data.message.include?('GETQUOTAROOT failed')
    end
  ]
  end,
 
  p(mimap.method('delete'),"INBOX/quota"), 
  p(mimap.method('logout'))  
]

#
# Tear Down
#
current.teardown = [      
  p(mimap.method('disconnect')),  
  DeleteAccount.new(testAccount.name)
]

if($0 == __FILE__)
  require 'engine/simple'
  
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run    
end