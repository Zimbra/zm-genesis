#!/usr/bin/ruby -w
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# IMAP SASL-IR
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
require "action/waitqueue"
require "action/decorator"
require "net/imap"; require "action/imap" #Patch Net::IMAP library
require "base64"

include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP SASL-IR test"

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
 
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD+'no')
adminAccount = Model::TARGETHOST.cUser('admin', Model::DEFAULTPASSWORD) 
Net::IMAP.add_authenticator('PLAIN', PlainAuthenticator)

class SASLImap < Net::IMAP 
  def authenticate(auth_type, *args)
    auth_type = auth_type.upcase
    unless @@authenticators.has_key?(auth_type)
      raise ArgumentError
        format('unknown auth type - "%s"', auth_type)
    end
    authenticator = @@authenticators[auth_type].new(*args) 
    send_command("AUTHENTICATE", auth_type, RawData.new(Base64.encode64(authenticator.process('')).gsub(/\n/,""))) 
  end   
end



mimap = d
mimap2 = d
mimap3 = d
mimap4 = d

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
  cb("Imap connection initialization") do
                    mimap.object =  SASLImap.new(Model::TARGETHOST, Model::IMAPSSL, true)
                    mimap2.object =  SASLImap.new(Model::TARGETHOST, Model::IMAPSSL, true)
                    mimap3.object =  SASLImap.new(Model::TARGETHOST, Model::IMAPSSL, true)
                    mimap4.object =  SASLImap.new(Model::TARGETHOST, Model::IMAPSSL, true)
                    
  end,
  # Authenticate using admin credential
  AuthVerify.new(mimap,  'AUTHENTICATE', 'PLAIN', testAccount.name, adminAccount.name, adminAccount.password),
  # Select
  v(proxy(mimap, 'select', "INBOX")) do |mcaller, data|
    mcaller.pass = data.class == Net::IMAP::TaggedResponse 
  end,
  v(proxy(mimap, 'fetch', 1, "BODY[TEXT]")) do |mcaller, data|
    mcaller.pass = data[0].attr.values.join.include?("test message")
  end,
  
  # Authentical using default
  AuthVerify.new(mimap2,  'AUTHENTICATE', 'PLAIN', '', testAccount.name, testAccount.password),
  # Select
  v(proxy(mimap2, 'select' ,"INBOX")) do |mcaller, data|
    mcaller.pass = data.class == Net::IMAP::TaggedResponse 
  end,
  
  # Authentical using default fully populated
  AuthVerify.new(mimap3,  'AUTHENTICATE', 'PLAIN', testAccount.name, testAccount.name, testAccount.password),
  # Select
  v(proxy(mimap3, 'select' ,"INBOX")) do |mcaller, data|
    mcaller.pass = data.class == Net::IMAP::TaggedResponse 
  end,
  
  # Text Plain must not be advertised in cleartext channel
#   v(proxy(mimap4.method('capability'))) do |mcaller, data|
#     mcaller.pass = ! data.any? {|x| x.include?('AUTH=PLAIN')}
#   end,
    
 
]

#
# Tear Down
#
current.teardown = [     
  proxy(mimap,'logout'),
  proxy(mimap,'disconnect'),  
  proxy(mimap2,'logout'),
  proxy(mimap2,'disconnect'),  
  proxy(mimap3,'logout'),
  proxy(mimap3,'disconnect'),
  proxy(mimap4,'logout'),
  proxy(mimap4,'disconnect'), 
  DeleteAccount.new(testAccount.name)
 
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end
 
