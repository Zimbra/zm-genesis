#!/usr/bin/ruby -w
#
# = action/login.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# IMAP login test cases
# 

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
current.description = "IMAP LOGIN test"

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

mimap = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true) 
mimap2 = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true) 

include Action


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
                  ZMProv.new('cad', 'foofoo.com',Model::TARGETHOST.to_s),
                  Action::SendMail.new(testAccount.name,'DummyMessageOne'),   
                  [['login'], ['login', testAccount.name], ['login', testAccount.name, testAccount.password, testAccount.name]].map do |x|
                    v(cb("Login Negative Test") do
                        mimap.method('send_command').call(*x) 
                      end, &IMAP::ParseError)
                  end , 
                  LoginVerify.new(mimap, testAccount.name, testAccount.password),
                  LoginVerify.new(mimap2, '%s@%s'%[name, 'foofoo.com'], testAccount.password),            
                  LoginVerify.new(mimap, testAccount.name, testAccount.password, &IMAP::MustNotInAuth),
                  
                  proxy(mimap.method('create'),"INBOX/one"), 
                  proxy(mimap.method('select'),'INBOX/one'), 
                  Action::SendMail.new(testAccount.name,'DummyMessageOne'), 
                  proxy(Kernel.method('sleep'),5),   
                  LoginVerify.new(mimap, testAccount.name, testAccount.password, &IMAP::MustNotInAuth),
                  proxy(mimap.method('noop')), 
                  proxy(mimap.method('delete'),"INBOX/one"),
                  #bunch of login extension
                  ['/tb', '/ni', '/wm'].map do |x| 
                    [testAccount.name+x, testAccount.name[/([^@]*)/]+x].map do |y|
                      v(cb("Extension  check #{x} for username #{y}") do 
                          mTemp = Net::IMAP.new(Model::TARGETHOST, *Model::TARGETHOST.imap) 
                          mResult = mTemp.login(y, testAccount.password) 
                          mTemp.logout
                          mTemp.disconnect 
                          mResult
                        end) do |mcaller, data|
                        mcaller.pass = data.class == Net::IMAP::TaggedResponse && data.name == 'OK'
                      end
                    end
                  end,
]

#
# Tear Down
#
current.teardown = [
                    proxy(mimap.method('logout')),  
                    proxy(mimap2.method('logout')),                     
                    proxy(mimap.method('disconnect')),  
                    proxy(mimap2.method('disconnect')),  
                    DeleteAccount.new(testAccount.name)
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end
