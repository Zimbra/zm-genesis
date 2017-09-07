#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2006 Zimbra
#
# Basic spam message test
#

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "net/imap"; require "action/imap" #Patch Net::IMAP library
require "model"
require "action/block" 
 
require "action/zmprov" 
require "action/sendmail" 
require "action/waitqueue" 
require "action/verify" 
require "action/zmcontrol"
require "action/zmprov"


#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Spam message test"

name = 'spam'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s 
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)
m = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)

include Action

message = <<EOF.gsub(/\n/, "\r\n").gsub(/DEST/, testAccount.name)
Subject: Test spam mail (GTUBE)
Message-ID: <GTUBE1.1010101@example.net>
From: genesis@zimbratest.com
To: DEST
Precedence: junk
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: 7bit

This is the GTUBE, the
	Generic
	Test for
	Unsolicited
	Bulk
	Email

If your spam filter supports it, the GTUBE provides a test by which you
can verify that the filter is installed correctly and is detecting incoming
spam. You can send yourself a test mail containing the following string of
characters (in upper case and with no white spaces and line breaks):

XJS*C4JDBQADN1.NSBN3*2IDNEN*GTUBE-STANDARD-ANTI-UBE-TEST-EMAIL*C.34X

You should send this test mail from an account outside of your network.

EOF

message2 = <<EOF.gsub(/\n/, "\r\n").gsub(/DEST/, testAccount.name)
Subject: Test spam mail (GTUBE)
Message-ID: <GTUBE1.1010101@example.net>
From: genesis@zimbratest.com
To: DEST
Precedence: junk
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: 7bit

This is only a test

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
  #Create accounts
  CreateAccount.new(testAccount.name,testAccount.password),
  Action::SendMail.new(testAccount.name,message), 
  Action::WaitQueue.new,    
  p(m.method('login'),testAccount.name,testAccount.password),
  p(m.method('select'), 'INBOX'),
  v(cb("Fetch Junk Kill Mail") do  
    m.fetch((1..-1), 'RFC822.HEADER')
  end) do  |mcaller, data|
    begin
      mcaller.pass = data[0].attr.values.join.include?('X-Spam-Score')
      mcaller.pass = false
    rescue
      mcaller.pass = true
    end 
  end,
  Action::SendMail.new(testAccount.name,message2),    
  Action::WaitQueue.new,    
  v(cb("Fetch Normal Mail") do  
    m.fetch((1..-1), 'RFC822.HEADER')
  end) do  |mcaller, data|
    begin
      mcaller.pass = data[0].attr.values.join.include?('X-Spam-Score')     
    rescue
      mcaller.pass = false
    end 
  end,
  Action::WaitQueue.new
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
