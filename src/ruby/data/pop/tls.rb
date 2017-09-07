#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2006 Zimbra
# POP TLS test
# 
if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"
require "action/block"
require "action/zmprov"
require "action/proxy" 
require "action/verify"
 
require "net/pop" ; require 'action/pop'

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "POP TLS test"

name = 'pop'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
 
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)  
pop = nil

include Action

message = <<EOF.gsub(/\n/, "\r\n")
Subject: hello
From: genesis@test.org
To: genesis@ruby-lang.org

Sequence message REPLACEME
one
two
three
four
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
  v(cb("TLS testing"){ 
    pop = Net::POP3.new(Model::TARGETHOST, *Model::TARGETHOST.pop)
    pop.tls = true
    pop.start(testAccount.name, testAccount.password)
  }) do |mcaller, data|
    mcaller.pass = data.started?
    data.finish unless data.nil?
  end,  
   
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