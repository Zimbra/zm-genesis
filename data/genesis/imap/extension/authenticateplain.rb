if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 

require "net/imap"; require "action/imap" #Patch Net::IMAP library 
require "model"

require "action/zmprov"
require "action/proxy"
require "action/sendmail"
require "action/verify"
require "action/waitqueue" 
require "base64"

include Action
#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP AUTHENTICATE PLAIN test"

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
 
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD+'no')
adminAccount = Model::TARGETHOST.cUser('admin', Model::DEFAULTPASSWORD) 
Net::IMAP.add_authenticator('PLAIN', PlainAuthenticator)


mimap = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)
mimap2 = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)
mimap3 = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)
mimap4 = Net::IMAP.new(Model::TARGETHOST, Model::IMAP, false)

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
  AuthVerify.new(mimap,  '', 'PLAIN', testAccount.name, adminAccount.name, adminAccount.password),
  # Select
  v(proxy(mimap.method('select'),"INBOX")) do |mcaller, data|
    mcaller.pass = data.class == Net::IMAP::TaggedResponse 
  end,
  v(proxy(mimap.method('fetch'), 1, "BODY[TEXT]")) do |mcaller, data|
    mcaller.pass = data[0].attr.values.join.include?("test message")
  end,
  
  # Authentical using default 
  AuthVerify.new(mimap2,  '', 'PLAIN', '', testAccount.name, testAccount.password),
  
  
  # Select
  v(proxy(mimap2.method('select'),"INBOX")) do |mcaller, data|
    mcaller.pass = data.class == Net::IMAP::TaggedResponse 
  end,
  # Bunch of extension switches
  ['/tb', '/ni', '/wm'].map do |x| 
    [testAccount.name+x, testAccount.name[/([^@]*)/]+x].map do |y|
      v(cb("Extension  check #{x} for username #{y}") do 
         mTemp = Net::IMAP.new(Model::TARGETHOST, *Model::TARGETHOST.imap) 
         mResult = mTemp.authenticate('PLAIN', y, testAccount.name, testAccount.password) 
         mTemp.logout
         mTemp.disconnect 
         mResult
      end) do |mcaller, data|
         mcaller.pass = data.class == Net::IMAP::TaggedResponse && data.name == 'OK'
     end
   end
  end,
  
  # Authentical using default fully populated
  AuthVerify.new(mimap3,  '', 'PLAIN', testAccount.name, testAccount.name, testAccount.password),
  # Select
  v(proxy(mimap3.method('select'),"INBOX")) do |mcaller, data|
    mcaller.pass = data.class == Net::IMAP::TaggedResponse 
  end,
  
  # Text Plain must not be advertised in cleartext channel
  #v(proxy(mimap4.method('capability'))) do |mcaller, data|
  #  mcaller.pass = ! data.any? {|x| x.include?('AUTH=PLAIN')}
  #end,
]

#
# Tear Down
#
current.teardown = [     
  proxy(mimap.method('logout')),
  proxy(mimap.method('disconnect')),  
  proxy(mimap2.method('logout')),
  proxy(mimap2.method('disconnect')),  
  proxy(mimap3.method('logout')),
  proxy(mimap3.method('disconnect')),
  proxy(mimap4.method('logout')),
  proxy(mimap4.method('disconnect')),  
  DeleteAccount.new(testAccount.name)
 
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end
 
