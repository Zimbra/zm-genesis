#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2012 Zimbra
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
current.description = "IMAP Tags"

include Action 

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)
Action::WaitQueue.new.run #make sure postfix queue is empty before set up imap connection..imap connection is timing sensitive
mimap = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)

tag = 'someTag'
mFolder1 = 'INBOX/fld1'
mFolder2 = 'INBOX/fld2'

message = <<EOF.gsub(/\n/, "\r\n").gsub(/REPLACEME/, testAccount.name)
Subject: hello
From: genesis@test.org
To: REPLACEME

hello world
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
  p(mimap.method('login'),testAccount.name,testAccount.password), 

  p(mimap.method('create'),mFolder1),
  p(mimap.method('create'),mFolder2), 

  cb("Add message to 1st folder") do
    mimap.append(mFolder1,message.gsub(/REPLACEME/,"1"), [], Time.now)    
  end,
  cb("Add message to 2nd folder") do
    mimap.append(mFolder2,message.gsub(/REPLACEME/,"2"), [], Time.now)    
  end,
  Action::WaitQueue.new,
 
  # create tag on a message in 1st folder
  ZMailAdmin.new('-m', testAccount.name, 'ct', tag),
  cb("Tag a message") do 
    result = ZMailAdmin.new('-m', testAccount.name, 's', '-t', 'message', "in:#{mFolder1}").run
    #TBD - use an xml parser for robustness
    ZMailAdmin.new('-m', testAccount.name, 'tm', result[1][/m .* id="(\d+)"/m, 1], tag).run       
  end,

  v(cb("SELECT 1st folder and FETCH") do
    result = Array.new
    mimap.select(mFolder1)
    result[1] = YAML.dump(mimap.responses["OK"])
    result[0] = YAML.dump(mimap.fetch(1..1,'FLAGS'))
    result
  end) do |mcaller, data|
    # should contain the tag
    mcaller.pass = data[1].include?(tag) && data[0].include?(tag)
  end,
  
  v(cb("SELECT 2nd folder") do
    mimap.select(mFolder2)
    YAML.dump(mimap.responses["OK"])
  end) do |mcaller, data|
    # should not contain tag yet
    mcaller.pass = !data.include?(tag)
  end,

  v(cb("STORE tag to the message in 2nd folder") do
    YAML.dump(mimap.store(1, "+FLAGS", [tag]))
  end) do |mcaller, data|
    # response should show tag added
    mcaller.pass = data.include?(tag)
  end,
  
  v(cb("SELECT on 2nd folder") do
    mimap.select(mFolder2)
    YAML.dump(mimap.responses["OK"])
  end) do |mcaller, data|
    # now second folder should contain tag
    mcaller.pass = data.include?(tag)
  end,
  
  v(cb("STORE not existing tag") do
    YAML.dump(mimap.store(1, "+FLAGS", [tag+tag]))
  end) do |mcaller, data|
    # response should show tag added
    mcaller.pass = data.include?(tag+tag)
  end,
  
  v(cb("SELECT on 2nd folder") do
    mimap.select(mFolder2)
    YAML.dump(mimap.responses["OK"])
  end) do |mcaller, data|
    # now second folder should contain tag
    mcaller.pass = data.include?(tag+tag)
  end,
  
  v(cb("IMAP tag is invisible for ZWC") do
    re = /<tags>(.+)<\/tags>/m
    result = ZMailAdmin.new('-m', testAccount.name, 'gat').run
    re.match(result[1])[1]
  end) do |mcaller, data|
    # new tag is not visible for SOAP
    mcaller.pass = !data.include?(tag+tag)
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

