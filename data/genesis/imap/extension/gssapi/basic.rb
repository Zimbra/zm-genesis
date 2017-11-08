#!/usr/bin/ruby -w
#
# = data/imap/fetch/basic.rb
#
# Copyright (c) 2010 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# IMAP Basic GSSAPI test
#
if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 


 
require "model"
require "action/block"

require "action/runcommand"
require "action/zmprov"
require "action/verify"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP GSSAPI"
current.skip = true #Skip this testcase till kerberos system is set up

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

m = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)
#m = Net::IMAP.new(Model::TARGETHOST, 7143)

include Action

 
#
# Setup
#
current.setup = [
   
]

#
# Execution
#
# doesn't work for proxy yet
# see http://www.zimbra.com/docs/ne/latest/administration_guide/ZimbraProxy.07.7.html
#
current.action = [  
                  CreateAccount.new('test001@testme.com', 'whatever'),
                  RunCommandOn.new('zqa-098.eng.vmware.com', 'kinit', 'root', '-k', 'test001@ZIMBRAQA.COM'), #this is kerberos system
                  v(RunCommandOn.new('zqa-098.eng.vmware.com', 'gsasl', 'root', 
                                     "--connect=%s"%Model::TARGETHOST, '-a', 'test001@testme.com', '-d')) do |mcaller, data|
                    mcaller.pass = data[1].include?('OK LOGOUT completed')
                  end
  
]

#
# Tear Down
#
current.teardown = [     
 
]

if($0 == __FILE__)
  require 'engine/simple'
  
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run    
end
