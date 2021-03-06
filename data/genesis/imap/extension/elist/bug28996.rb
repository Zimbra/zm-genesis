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
#
if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 

require "net/imap"; require "action/imap" #Patch Net::IMAP library 
require "model"
require "action/block"

require "action/zmprov"
require "action/proxy"
require "action/verify"



#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP List extension test"

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

include Action

mimap = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true) 

#
# Setup
#
current.setup = [
  
]

#
# Execution
#
current.action = [  
  Action::CreateAccount.new(testAccount.name,testAccount.password),
  p(mimap.method('login'),testAccount.name,testAccount.password),
  p(mimap.method('create'),"INBOX/one"),
  p(mimap.method('create'),"INBOX/one/two"),
  p(mimap.method('subscribe'),"INBOX/one/two"), 
  
 
  
  v(cb("Basic recursive subscribed") do 
    response = mimap.elist('','%',%w[RECURSIVEMATCH SUBSCRIBED]) 
    response
  end) do |mcaller, data| 
    mcaller.pass = (data.size == 1) &&
    data.first.class == Net::IMAP::MailboxListE &&
    data.first.name == 'INBOX' &&
    data.first.attr.any? {|x| x == :Haschildren} &&
    data.first.children.any? {|x| x == 'SUBSCRIBED'}
    puts YAML.dump(data) if $DEBUG 
  end, 
  
  v(cb("Basic recursive subscribed return children") do 
    response = mimap.elist('','*',%w[RECURSIVEMATCH SUBSCRIBED] ) 
    response
  end) do |mcaller, data|
    mcaller.pass = (data.size == 1) &&
       data.first.class == Net::IMAP::MailboxList &&
       data.first.name == 'INBOX/one/two' &&
       data.first.attr.any? {|x| x == :Hasnochildren } &&
       data.first.attr.any? {|x| x == :Subscribed } 
      puts YAML.dump(data) if $DEBUG 
  end,  
  
  p(mimap.method('delete'),"INBOX/one/two"),
  p(mimap.method('delete'),"INBOX/one"), 
  p(mimap.method('logout')),
  p(mimap.method('disconnect')),
]

#
# Tear Down
#
current.teardown = [     
    
  Action::DeleteAccount.new(testAccount.name)
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end