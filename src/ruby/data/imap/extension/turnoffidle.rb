if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"

require "action/zmprov"
require "action/proxy"
require "action/sendmail"
require "action/verify"
require "action/waitqueue"
require "net/imap"; require "action/imap" #Patch Net::IMAP library
require "base64"

include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP Turn off idle test"

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
 
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD+'no')
adminAccount = Model::TARGETHOST.cUser('admin', Model::DEFAULTPASSWORD) 
Net::IMAP.add_authenticator('PLAIN', PlainAuthenticator)


mimap = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true) 
mimap3 = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)
 


message = <<EOF.gsub(/\n/, "\r\n")
Subject: hello
From: genesis@test.org
To: genesis@ruby-lang.org

test message
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
  SendMail.new(testAccount.name, message),
  Action::WaitQueue.new, 
  
  # Authenticate using admin credential
  AuthVerify.new(mimap,  'AUTHENTICATE', 'PLAIN', testAccount.name+'/ni', adminAccount.name, adminAccount.password) do |mcaller, data|
    mdata = mimap.capability
    mcaller.pass = ! mdata.include?("IDLE")
  end,
   
  # Authentical using default fully populated
  AuthVerify.new(mimap3,  'AUTHENTICATE', 'PLAIN', testAccount.name+'/ni', testAccount.name, testAccount.password) do |mcaller, data|
    mdata = mimap3.capability
    mcaller.pass = ! mdata.include?("IDLE")
  end,
  
  # Plain old login
  v(cb("login with no idle") do
    mimap4 = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)
    mimap4.login(testAccount.name+'/ni', testAccount.password)
    result = mimap4.capability
    mimap4.logout
    mimap4.disconnect
    result
  end) do |mcaller, data|
    mcaller.pass = ! data[1].include?("IDLE")
  end 
 
]

#
# Tear Down
#
current.teardown = [     
  proxy(mimap.method('logout')),
  proxy(mimap.method('disconnect')),  
  proxy(mimap3.method('logout')),
  proxy(mimap3.method('disconnect')), 
  DeleteAccount.new(testAccount.name) 
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end
 