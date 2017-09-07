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
require "action/decorator"
require "action/proxy"
require "action/sendmail"
require "action/verify"
require "action/waitqueue"
require "action/zmprov"

require "net/imap"; require "action/imap" #Patch Net::IMAP library

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP Select Negative test"

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
name = "admin" if ($0 == __FILE__)
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

include Action

mimap = d
#Net::IMAP.debug = true 
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
  Action::SendMail.new(testAccount.name,'DummyMessageOne'),  
  Action::WaitQueue.new,
  cb("Imap connection initialization") do
    mimap.object =  Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)                                  
  end,
  
  #bug 57420 won't fix - expect different behaviour for proxy and non-proxy
  if Model::TARGETHOST.proxy
    SelectVerify.new(mimap, "INBOX", &IMAP::badResponseError(IMAP::badString)) 
  else
    SelectVerify.new(mimap, "INBOX", &IMAP::MustInAuthSelect) 
  end,
  
  proxy(mimap, 'login' ,testAccount.name,testAccount.password),
  
  ['INBOX/one', 'INBOX/two', 'INBOX/three/three'].map do |x|
    proxy(mimap, 'create', x)
  end,
  
  ['nothere', '\Answered', '=me', '///', '\\\\', ''].map do |x|
    SelectVerify.new(mimap, x, &IMAP::SelectFailed)
  end,
  
  #bug 75974
  ['/home/nonexsisting/account', "/home/#{testAccount.name}/", "/home/#{testAccount.name}/INBOX"].map do |x| 
    SelectVerify.new(mimap, x, &IMAP::SelectFailed)
  end,
  
  v(proxy(mimap, 'select' , 'INBOX/'*1000)) do |caller, data|
    caller.pass = data.message.include?('SELECT failed')    
  end,
                  
  v(cb("large select: over the limit", 180) do          
    response = nil 
    begin
      timeout(120) do
        mimap.method('send_command').call("select #{'INBOX/'*1000000}") { |data| response = data }           
      end  
    rescue => e
      response = e
    end  
    response
    end ) do |mcaller, data|
      mcaller.pass = data.class == Timeout::Error || data.class == OpenSSL::SSL::SSLError || data.class == Net::IMAP::BadResponseError
      mcaller.suppressDump("Suppressed since too long output expected") if(!mcaller.pass)
  end, 
                
  ZMProv.new('ms', Model::TARGETHOST.to_str, 'zimbraImapMaxRequestSize', 6291456),
  cb("wait") {sleep(10)},              
  
  v(cb("large select: below the limit", 180) do          
    response = nil 
    begin
      timeout(120) do
        mimap.method('send_command').call("select #{'INBOX/'*1000000}") { |data| response = data }           
      end  
    rescue => e
      response = e
    end  
    response
    end ) do |mcaller, data|
      mcaller.pass = data.class == Timeout::Error || data.class == OpenSSL::SSL::SSLError || data.class == Net::IMAP::NoResponseError
      mcaller.suppressDump("Suppressed since too long output expected") if(!mcaller.pass)
  end, 
                
  ZMProv.new('ms', Model::TARGETHOST.to_str, 'zimbraImapMaxRequestSize', 10240), #set it back to default
  
  proxy(mimap, 'status', 'INBOX', ["MESSAGES", "RECENT", "UIDNEXT","UNSEEN", "UIDVALIDITY"]),  
  
  ["INBOX/three/three", "INBOX/three", "INBOX/two", "INBOX/one"].map do |x|
    proxy(mimap, 'delete', x)
  end, 
  
  proxy(mimap, 'logout'),
  ]

#
# Tear Down
#
current.teardown = [     
  proxy(mimap, 'disconnect'),
  DeleteAccount.new(testAccount.name)
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end
