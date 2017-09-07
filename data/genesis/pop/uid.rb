#!/usr/bin/ruby -w
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# POP UID Plain
# 
if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"
require "action/block"
require "action/zmprov"
require "action/proxy" 
require "action/verify"
require "net/imap"; require "action/imap" #Patch Net::IMAP library
require "net/pop"
require "set"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "POP UID test"

name = 'pop'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
name = "admin" if ($0 == __FILE__)
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

mimap = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)
pop = Net::POP3.new(Model::TARGETHOST, *Model::TARGETHOST.pop)

include Action

message = <<EOF.gsub(/\n/, "\r\n")
Subject: hello
From: genesis@test.org
To: genesis@ruby-lang.org

Sequence message REPLACEME
EOF

flags = [:Answered, :Draft, :Deleted, :Flagged, :Seen, '$FORWARDED', 'JUNK', 'NONJUNK', 'NOTJUNK', 'DUMMY', 'NIL']
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
  p(mimap.method('login'),testAccount.name,testAccount.password),
  #clean up
  p(mimap.method('select'),'INBOX'),
  p(mimap.method('store'), 1..1000, "FLAGS", [:DELETED]),
  p(mimap.method('close')),   
  cb("Create 20 messages") {     
    0.upto(19) { |i|                
      cflags = [flags[(i+4)%flags.size]]
      mimap.append("INBOX",message.gsub(/REPLACEME/,i.to_s),cflags, Time.now)    
      "Done"
    }
  },
   
  #pop action
  v(cb("Simple 20 mails fetch") {
    response = []  
    response2 = [] 
    pop.start(testAccount.name, testAccount.password)
    exitcode = 1
    if pop.mails.empty?
      response = ["Failure no mail"]      
    else
      pop.mails.select { |m| response.push(m.unique_id) }  
      #response = response + Array.new(20) { |i| pop.method('command').call.uidl(i+1) }
      response2 = pop.method('command').call.uidl.to_a.map do |x|
        x[1]
      end 
      exitcode = 0
    end       
    [exitcode, response, response2]
  }) do |mcaller, data| 
    mcaller.pass = (data[0] == 0) && (data[1].to_set == data[2].to_set)
  end,   
  p(mimap.method('logout')),  
]

#
# Tear Down
#
current.teardown = [     
  proxy(mimap.method('disconnect')),
  DeleteAccount.new(testAccount.name)
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end