#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2012 Zimbra
#
# Bug 65556
# Ignore content-class header field when no other headers are requested
#
if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"
require "action/block"

require "action/zmprov"
require "action/proxy"
require "action/sendmail"
require "action/verify"
require "net/imap"; require "action/imap" #Patch Net::IMAP library

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP Fetch - ignore content-class header field"

name = 'ifetch'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
name = "admin" if ($0 == __FILE__)
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

m = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)

include Action

#
# Setup
#
current.setup = [
   CreateAccount.new(testAccount.name,testAccount.password) 
]

#
# Execution
#
current.action = [  
  p(m.method('login'),testAccount.name,testAccount.password),
  p(m.method('create'),"INBOX/FETCHBASIC"),
  cb("Create 1 messages using append") do
    message = IO.readlines(File.join(Model::DATAPATH, 'imap', 'email_to_fetch.txt')).join
    m.append("INBOX/FETCHBASIC",message ,[:Seen], Time.now) 
  end,

  p(m.method('select'),"INBOX/FETCHBASIC"),
  
  v(cb("fetch with only content-class header should be filtered") do
      result = Array.new
      result[0] = m.fetch('1:1', '(FLAGS UID)')
      result[1] = m.fetch('1:1', '(FLAGS UID BODY.PEEK[HEADER.FIELDS (content-class)])')
      result[2] = m.fetch('1:1', '(FLAGS UID BODY[HEADER.FIELDS (content-class)])')
      result
    end) do |mcaller, data|
      mcaller.pass = (data[0] == data[1]) && (data[0] == data [2])
  end,

  v(cb("fetch with multiple headers should not be filtered") do
      result = Array.new
      result[0] = m.fetch('1:1', '(FLAGS UID BODY.PEEK[HEADER.FIELDS (date subject from to cc content-class)])')
      result[1] = m.fetch('1:1', '(FLAGS UID BODY[HEADER.FIELDS (date subject from to cc content-class)])')
      result.map { |r| r[0][:attr]["BODY[HEADER.FIELDS (DATE SUBJECT FROM TO CC CONTENT-CLASS)]"]}
      result
    end) do |mcaller, data|
      mcaller.pass = data[0] && data[1]
  end,

  p(m.method('delete'),"INBOX/FETCHBASIC"),  
]

#
# Tear Down
#
current.teardown = [     
  p(m.method('logout')),
  p(m.method('disconnect')),  
  DeleteAccount.new(testAccount.name)
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run    
end

