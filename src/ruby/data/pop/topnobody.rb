#!/usr/bin/ruby -w
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2010 VMWARE
#
# pop top boundry test
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

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "POP Top boundary test"

name = 'pop'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

mimap = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)
pop = Net::POP3.new(Model::TARGETHOST, *Model::TARGETHOST.pop)

include Action

message = <<EOF.gsub(/\n/, "\r\n")
Subject: whatever

oh ya
yada yada so so what

EOF

flags = [:Answered, :Draft, :Flagged, :Seen, '$FORWARDED', 'JUNK', 'NONJUNK', 'NOTJUNK', 'DUMMY', 'NIL']
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
  p(mimap.method('login'),testAccount.name,testAccount.password),  
  p(mimap.method('select'),'INBOX'),
  cb("Create message") {        
      cflags = [flags[4%flags.size]]
      mimap.append("INBOX",message.gsub(/REPLACEME/,'0'),cflags, Time.now)    
      "Done"
  },
  v(cb("Top testing"){
    response = []
    pop.start(testAccount.name, testAccount.password)
    pop.each_mail do |m| 
        response.push(m.top(0)) 
        response.push(m.top(1))
    end    
    response
  }) do |mcaller, data|
    mcaller.pass = (data.first.split(/\n/).size == 2) && (data.pop.split(/\n/).size == 3)
  end,  #todo implement uniqueness check
  p(pop.method('finish')),
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
