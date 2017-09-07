#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
#
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
require "action/verify"
require "action/sendmail" 
require "action/waitqueue"
require "action/decorator"

message = <<EOF.gsub(/\n/, "\r\n")
Subject: hello
From: genesis@test.org
To: REPLACEME 

Search body message hmm
  Orange 
    Apple
      Pear.
Garbage.
me. "Quoted"
EOF


#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP Status in List"

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

include Action

mimap = d

#
# Setup
#
current.setup = [
                 
                ]

#
# Execution
#
current.action = [  
                  Action::CreateAccount.new(testAccount.name,testAccount.password),
                  Action::SendMail.new(testAccount.name,'DummyMessageOne'), 
                  Action::WaitQueue.new,
                  cb("Imap connection initialization") do
                    mimap.object =  Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)                                  
                  end,
                  p(mimap, 'login', testAccount.name,testAccount.password),
                  
                  v(cb("Basic Status in ELIST") do
 
                      response = mimap.elist('','*', nil, ['STATUS', %w[MESSAGES RECENT UIDNEXT UIDVALIDITY UNSEEN]])
                      mimap.responses['STATUS']
                    end) do |mcaller, data|
                    
                    inbox = data.select { |x| x.mailbox == 'INBOX'}
                    if(inbox.nil?)
                      mcaller.pass = false
                    else
                      first_one = inbox.first
                      mcaller.pass = %w[UIDVALIDITY UNSEEN RECENT MESSAGES].map do |x|
                        first_one.attr[x] == 1
                      end.all? { |y | y == true}
                    end
                  
                    puts YAML.dump(data) if $DEBUG 
                  end, 
                  
                  p(mimap, 'logout'),
                  p(mimap, 'disconnect'),
                 ]

#
# Tear Down
#
current.teardown = [     
                    
                    Action::DeleteAccount.new(testAccount.name)
                   ]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end
