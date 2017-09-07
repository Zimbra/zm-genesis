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
# 

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model" 
require "action/block"

require "action/zmprov"
require "action/zmmailbox"
require "action/proxy"
require "action/sendmail"
require "action/verify"
require "action/waitqueue"
require "net/imap"; require "action/imap" #Patch Net::IMAP library


#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP Illegal Map"

include Action 

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)
Action::WaitQueue.new.run #make sure postfix queue is empty before set up imap connection..imap connection is timing sensitive
mimap = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)
tagList = ['dog%cat',  'dog]cat', 'dog*cat', '***']


 
#
# Setup
#
current.setup = [
  
]
message = <<EOF.gsub(/\n/, "\r\n").gsub(/REPLACEME/, testAccount.name)
Subject: hello
From: genesis@test.org
To: REPLACEME

hello world
EOF
#
# Execution
#
current.action = [  
  CreateAccount.new(testAccount.name,testAccount.password),
  cb("Send an email") {
    SendMail.new(testAccount.name,message).run
  }, 
  Action::WaitQueue.new,
  p(mimap.method('login'),testAccount.name,testAccount.password), 
 
  # create bunch of tags
  tagList.map do |x|
    ZMailAdmin.new('-m', testAccount.name, 'ct', x)
  end,
  #ZMailAdmin.new('-m', testAccount.name, 'gat'),
  cb("Tag a message") do 
    result = ZMailAdmin.new('-m', testAccount.name, 's', '-t', 'message', 'in:inbox').run
    re = /id="(\d+)" d=/m   
    md = re.match(result[1])
    tagList.each do |u|
      ZMailAdmin.new('-m', testAccount.name, 'tm', md[1], u).run       
    end    
    #result = ZMailAdmin.new('-m', testAccount.name, 'gm', md[1]).run
  end,
  p(mimap.method('select'), 'INBOX'),
  v(cb("Check See if illegal is stripped") do    
    YAML.dump(mimap.fetch(1..1,'FLAGS'))
  end) do |mcaller, data|
    #make sure it does not contain original tag
    mcaller.pass = ! tagList.any? {|x| data.include?(x)}   
  end,
  p(mimap.method('logout')),  
]

#
# Tear Down
#
current.teardown = [      
  p(mimap.method('disconnect')),  
  DeleteAccount.new(testAccount.name)
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance, false).run  
end 
