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

require "action/zmprov"
require "action/block"
require "action/proxy"
require "action/verify"
require "action/zmsoap"
require "net/imap"; require "action/imap" #Patch Net::IMAP library

Net::IMAP.add_authenticator('PLAIN', Action::PlainAuthenticator)
#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP Password Pattern test"

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s 
testAccount = Model::TARGETHOST.cUser(name, 'test%') 
mimap = nil
include Action

#
# Setup
#
current.setup = [
   
]
passList = %w[%%%%%%% %test123 test123% test%123]  
passList = passList + ['i have space', 'hmmmmm*', '*******', "tabtabtab\t", "\ttabtabtab"]
passList = passList + ['bracketbracket[', 'bracketbracket]', 'para(para', 'para)para', 'backslash\\back'] 
#
# Execution
#
current.action = [
  
  passList.map do |x|
    [
      CreateAccount.new(testAccount.name, 'test123'),
      ZMSoap.new('-z', '-m', testAccount.name, '-t account', "ChangePasswordRequest/account=#{testAccount.name} @by=name ../oldPassword='test123' ../password=#{'"'+x+'"'}"),
      v(cb("Login test") do  
        mimap = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)  
        mresponse = mimap.login(testAccount.name, x)
        mimap.logout
        mimap.disconnect
        mresponse
      end) do |mdata, data|
        mdata.pass = data['name'] == 'OK'
        if not mdata.pass
          class << mdata
            attr_writer :password
          end
          mdata.password = x
        end
      end,  
      
      v(cb("Auth Plain") do  
        mimap = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)   
        mresponse = mimap.authenticate('PLAIN', '', testAccount.name, x)
        mimap.logout
        mimap.disconnect
        mresponse
      end) do |mdata, data|
        mdata.pass = data['name'] == 'OK'
        if not mdata.pass
          class << mdata
            attr_writer :password
          end
          mdata.password = x
        end
      end, 
      DeleteAccount.new(testAccount.name)
    ]
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
