#!/usr/bin/ruby -w
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2006 Zimbra
#
#
if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 

require "net/imap"; require "action/imap" #Patch Net::IMAP library 
require "model" 
require "action/block"
require "action/zmprov"
require "action/proxy"
require "action/sendmail"
require "action/verify" 
 #should be after net/imap since it patches class method


# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP Saved search result basic"

name = 'isavesearch'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD) 
m = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)
#m = Net::IMAP.new(Model::TARGETHOST, Model::IMAP)
#Net::IMAP.debug = true

include Action

message = <<EOF.gsub(/\n/, "\r\n")
Subject: hello
From: genesis@test.org
To: genesis@ruby-lang.org

Search message REPLACEME
EOF


 
#
# Setup
#
current.setup = [
   
]

#
# Execution
#
current.action = [  
  CreateAccount.new(testAccount.name,testAccount.password),
  p(m.method('login'),testAccount.name,testAccount.password),
  p(m.method('create'),"INBOX/all"),
  cb("Create 20 messages using append") {       
    1.upto(20) { |i|
      m.append("INBOX/all",message.gsub(/REPLACEME/,i.to_s),[:Seen], Time.now) 
    }
    "Done"
  }, 
  v(cb("Must be in SELECTED state") do
    begin
      m.fetch('$', 'UID') 
    rescue => e 
      e
    end
  end) do |mcaller, data|
    mcaller.pass = data.class == Net::IMAP::NoResponseError
  end,

  p(m.method('select'),"INBOX/all"), 
  v(cb("Empty Sequence") do
    m.fetch('$', 'UID')
  end) do |mcaller, data|
    mcaller.pass = data.nil?
  end,
  
  v(cb("Basic $ setting test") do 
    m.esearch('RETURN (SAVE) 15:16')    
    m.esearch('RETURN (ALL) ALL')
    m.fetch('$', 'UID')
  end) do |mcaller, data| 
    
    mcaller.pass = (data.size == 2) &&
      data.all? do |x| 
        (x.class == Net::IMAP::FetchData) &&
        ([15, 16].any? {|y| y == x.seqno })
    end 
  end,  
  p(m.method('select'),"INBOX"), 
  v(cb("Empty Sequence After Saved") do
    m.fetch('$', 'UID')
  end) do |mcaller, data|
    mcaller.pass = data.nil?
  end,
  p(m.method('select'),"INBOX/all"), 
  
  v(cb("Double Search Test") do 
    m.esearch('RETURN (SAVE) 15:16')     
    m.method('send_command').call('SEARCH CHARSET WHATEVER (OR $ 1,3000:3021) TEXT "xxxx"') rescue nil
    m.method('send_command').call('SEARCH $ SMALLER 40960')
    m.responses
  end) do |mcaller, data|   
    mcaller.pass = data["SEARCH"] && data["SEARCH"].first.size == 2 &&
    data["SEARCH"].first.all? {|x| (x == 15) || (x == 16)} 
  end,   
  
   v(cb("Empty Copy") do 
    m.esearch('RETURN (SAVE) SMALLER 1')    
    m.copy('$','Inbox')   
  end) do |mcaller, tagResponse|    
    mcaller.pass = tagResponse.data.text == 'COPY completed' 
  end,   
  
  p(m.method('delete'),"INBOX/all"),  
  p(m.method('logout')),
  p(m.method('disconnect')),   
  
]

#
# Tear Down
#
current.teardown = [     
 
  DeleteAccount.new(testAccount.name)
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end