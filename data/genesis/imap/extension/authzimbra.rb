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
require "action/zmsoap"

include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP AUTHENTICATE X-ZIMBRA test"

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s

testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD+'no')
adminAccount = Model::TARGETHOST.cUser('admin', Model::DEFAULTPASSWORD)
Net::IMAP.add_authenticator('X-ZIMBRA', XZimbraAuthenticator)

mimap = Net::IMAP.new(Model::TARGETHOST, *Model::TARGETHOST.imap)
mimap2 = Net::IMAP.new(Model::TARGETHOST, *Model::TARGETHOST.imap)
mimap3 = Net::IMAP.new(Model::TARGETHOST, *Model::TARGETHOST.imap)
mimap4 = Net::IMAP.new(Model::TARGETHOST, *Model::TARGETHOST.imap)

message = <<EOF.gsub(/\n/, "\r\n")
Subject: hello
From: genesis@test.org
To: genesis@ruby-lang.org

test message
EOF

#Net::IMAP.debug = true
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
  # Authenticate using default fully populated
  v(cb("Authenticate X-Zimbra populated") do
    stoken = ZMSoapUtils.getAccountToken(testAccount)
    mimap.authenticate('X-ZIMBRA', testAccount.name, testAccount.name, stoken)
  end) do |mcaller, data|
    mcaller.pass = data.class == Net::IMAP::TaggedResponse && data.name == 'OK'
  end,

  # Select
  v(proxy(mimap.method('select'),"INBOX")) do |mcaller, data|
    mcaller.pass = data.class == Net::IMAP::TaggedResponse
  end,

  # Authentical using default
  v(cb("Authenticate X-Zimbra with default") do
    stoken = ZMSoapUtils.getAccountToken(testAccount)
    mimap2.authenticate('X-ZIMBRA', testAccount.name, testAccount.name, stoken)
  end) do |mcaller, data|
    mcaller.pass = data.class == Net::IMAP::TaggedResponse && data.name == 'OK'
  end,

  # Examine
  v(proxy(mimap2.method('examine'),"INBOX")) do |mcaller, data|
    mcaller.pass = data.class == Net::IMAP::TaggedResponse
  end,

  # Authenticate using admin auth token from web client - should be rejected
  v(cb("Authenticate X-Zimbra as admin with WS token") do
    stokenAdmin = ZMSoapUtils.getAccountToken(adminAccount)
    mimap3.authenticate('X-ZIMBRA', testAccount.name, adminAccount.name, stokenAdmin)
  end) do |mcaller, data|
    mcaller.pass = data.class == Net::IMAP::NoResponseError && data.message.include?("AUTHENTICATE failed")
  end,

  # Authenticate using admin auth token from admin console - should be accepted
  v(cb("Authenticate X-Zimbra as admin with AC token") do
    stokenAdmin = ZMSoapUtils.getAdminAccountToken(adminAccount)
    mimap4.authenticate('X-ZIMBRA', testAccount.name, adminAccount.name, stokenAdmin)
  end) do |mcaller, data|
    mcaller.pass = data.class == Net::IMAP::TaggedResponse && data.name == 'OK'
  end,
  # Select
  v(proxy(mimap4.method('select'),"INBOX")) do |mcaller, data|
    mcaller.pass = data.class == Net::IMAP::TaggedResponse
  end,

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

