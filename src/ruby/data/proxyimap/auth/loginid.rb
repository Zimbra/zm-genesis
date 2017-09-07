#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# Ability to do POP3/IMAP login with a user id other than user's mail addresses
# bug #21794
#
#
if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 

require "net/imap"; require "action/imap" #Patch Net::IMAP library
require "model"
require "action/zmprov"
require "action/proxy"
require "action/verify"
require "action/zmcontrol"
require "action/waitqueue" 
require "base64"

require "net/pop"; require "action/pop"

include Action
#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "POP/IMAP login with id different than mail address"

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)
id = 'foo'
id_domain = 'testdomain.what.com'

oldHostQuery = ''
newHostQuery = '"(|(zimbraMailDeliveryAddress=\${USER})(zimbraMailAlias=\${USER})(zimbraId=\${USER})(zimbraForeignPrincipal=\${USER}))"'

Net::IMAP.add_authenticator('PLAIN', PlainAuthenticator)

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

  if (Model::TARGETHOST.proxy == true)
    [
      #set up login id for an account
      cb("Set up", 180) do
        ZMProv.new('cd',id_domain).run
        ZMProv.new('mcf', 'zimbraDefaultDomainName', id_domain).run
        oldHostQuery = ZMProv.new('gcf', 'zimbraReverseProxyMailHostQuery').run[1]
        oldHostQuery.chomp!
        oldHostQuery.sub!('zimbraReverseProxyMailHostQuery: ', '')
        oldHostQuery.gsub!('$', '\$')
        oldHostQuery = '"'+oldHostQuery+'"'
        ZMProv.new('mcf', 'zimbraReverseProxyMailHostQuery', newHostQuery).run
        ZMProv.new('mcf','zimbraReverseProxyUserNameAttribute', 'zimbraMailDeliveryAddress').run
        ZMProv.new('ma', testAccount.name, 'zimbraForeignPrincipal', id + '@' + id_domain).run
        ZMProv.new('aaa', testAccount.name, 'alias' + testAccount.name).run
      end,
      
      ZMControl.new('restart'),
      #
      ## IMAP
      #
      v(cb("IMAP: id login") do
          mTemp = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)
          mResult = mTemp.login(id, testAccount.password)
          mTemp.logout; mTemp.disconnect 
          mResult
        end) do |mcaller, data|
          mcaller.pass = data.class == Net::IMAP::TaggedResponse && data.name == 'OK'
      end,
      v(cb("IMAP: id and id_domain login") do
          mTemp = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)
          mResult = mTemp.login(id + '@' + id_domain, testAccount.password)
          mTemp.logout; mTemp.disconnect 
          mResult
        end) do |mcaller, data|
          mcaller.pass = data.class == Net::IMAP::TaggedResponse && data.name == 'OK'
      end,
      v(cb("IMAP: full account login") do
          mTemp = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)
          mResult = mTemp.login(testAccount.name, testAccount.password)
          mTemp.logout; mTemp.disconnect 
          mResult
        end) do |mcaller, data|
          mcaller.pass = data.class == Net::IMAP::TaggedResponse && data.name == 'OK'
      end,
      v(cb("IMAP: alias login") do
          mTemp = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)
          mResult = mTemp.login('alias' + testAccount.name, testAccount.password)
          mTemp.logout; mTemp.disconnect 
          mResult
        end) do |mcaller, data|
          mcaller.pass = data.class == Net::IMAP::TaggedResponse && data.name == 'OK'
      end,
      cb("set connection") do
        mimap = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)
        AuthVerify.new(mimap,  '', 'PLAIN', '', testAccount.name, testAccount.password).run
        end,
      
      v(cb("IMAP: auth plain id") do
          mTemp = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)
          mResult = mTemp.authenticate('PLAIN', '', id, testAccount.password)
          mTemp.logout; mTemp.disconnect 
          mResult
        end) do |mcaller, data|
          mcaller.pass = data.class == Net::IMAP::TaggedResponse && data.name == 'OK'
      end,
      v(cb("IMAP: auth plain full name") do
          mTemp = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)
          mResult = mTemp.authenticate('PLAIN', testAccount.name,testAccount.name, testAccount.password)
          mTemp.logout; mTemp.disconnect 
          mResult
        end) do |mcaller, data|
          mcaller.pass = data.class == Net::IMAP::TaggedResponse && data.name == 'OK'
      end,        

      # POP3
      
      v(cb("POP: id login") do
          mTemp = Net::POP3.new(Model::TARGETHOST, Model::POP)
          mTemp.start(id, testAccount.password)
        end) do |mcaller, data|
          mcaller.pass = data.started?
          data.finish unless data.class != Net::POP3
      end,
      v(cb("POP: id and id_domain login") do
          mTemp = Net::POP3.new(Model::TARGETHOST, Model::POP)
          mTemp.start(id + '@' + id_domain, testAccount.password)
        end) do |mcaller, data|
          mcaller.pass = data.started?
          data.finish unless data.class != Net::POP3
      
      end,
      v(cb("POP: full account login") do
          mTemp = Net::POP3.new(Model::TARGETHOST, Model::POP)
          mTemp.start(testAccount.name, testAccount.password)
        end) do |mcaller, data|
          mcaller.pass = data.started?
          data.finish unless data.class != Net::POP3
      end,
      v(cb("POP: alias login") do
          mTemp = Net::POP3.new(Model::TARGETHOST, Model::POP)
          mTemp.start('alias' + testAccount.name, testAccount.password)
        end) do |mcaller, data|
          mcaller.pass = data.started?
          data.finish unless data.class != Net::POP3
      end,
      
      v(cb("POP: auth plain full account") do
          mTemp = Net::POP3::AuthPlain.new(Model::TARGETHOST, *Model::TARGETHOST.pop)
          mTemp.start(testAccount.name, testAccount.password, testAccount.name)
        end) do |mcaller, data|
          mcaller.pass = data.started?
          data.finish unless data.class != Net::POP3
      end,
      
      v(cb("POP: auth plain for id") do
          mTemp = Net::POP3::AuthPlain.new(Model::TARGETHOST, *Model::TARGETHOST.pop)
          mTemp.start(id, testAccount.password, '')
        end) do |mcaller, data|
          mcaller.pass = data.started?
          data.finish unless data.class != Net::POP3
      end,
      
      # restore initial state
      cb("Restore") do
        ZMProv.new('dd',id_domain).run
        ZMProv.new('mcf', 'zimbraDefaultDomainName', Model::TARGETHOST.to_s).run
        ZMProv.new('mcf', 'zimbraReverseProxyMailHostQuery', oldHostQuery).run
        ZMProv.new('mcf','zimbraReverseProxyUserNameAttribute', '""').run
      end,
      
      ZMControl.new('restart'),
    ]

  end
]

#
# Tear Down
#
current.teardown = [     
  DeleteAccount.new(testAccount.name)
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end 

