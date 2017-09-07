if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"
require "action/zmprov"
require "action/proxy"
require "action/sendmail"
require "action/verify"
require "net/imap"; require "action/imap" #Patch Net::IMAP library

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP AUTHENTICATE test"

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
name = "admin" if ($0 == __FILE__)
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

mimap = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)

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
  v( #Missing Argument
    proxy(mimap.method('send_command'),'AUTHENTICATE')
  ) { |caller, data| 
    caller.pass = (data.class == Net::IMAP::BadResponseError) && 
      (data.message.include?(Action::IMAP.badString))         
  },  
  
  v( #Not Supported Mechanism
    proxy(mimap.method('authenticate'),'LOGIN', testAccount.name, testAccount.password)
  ) { |caller, data|
   caller.pass = (data.class == Net::IMAP::NoResponseError) && 
      (data.message.include?("not supported"))         
  }, 
  
  v(  #Not Supported Mechanism
    proxy(mimap.method('authenticate'),'CRAM-MD5', testAccount.name, testAccount.password)
  ) { |caller, data|
       caller.pass = (data.class == Net::IMAP::NoResponseError) && 
      (data.message.include?("not supported"))   
  },
  
  proxy(mimap.method('login'),testAccount.name,testAccount.password),
  v(
    proxy(mimap.method('authenticate'),'LOGIN', testAccount.name, testAccount.password)
  ) { |caller, data|
     caller.pass = (data.class == Net::IMAP::NoResponseError) && 
      (data.message.include?("NOT AUTHENTICATED state"))     
  }, 
  proxy(mimap.method('select'),"INBOX"), 
  v(
    proxy(mimap.method('authenticate'),'LOGIN', testAccount.name, testAccount.password)
  ) { |caller, data|
     caller.pass = (data.class == Net::IMAP::NoResponseError) && 
      (data.message.include?("NOT AUTHENTICATED state"))
  },
  proxy(Kernel.method('sleep'),5),
]

#
# Tear Down
#
current.teardown = [     
  proxy(mimap.method('logout')),
  proxy(mimap.method('disconnect')),  
  DeleteAccount.new(testAccount.name)
 
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end
 