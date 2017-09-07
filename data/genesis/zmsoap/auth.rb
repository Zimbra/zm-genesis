#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2014 Zimbra
#
# Verification of AuthResponse 
#

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "action/verify"
require "action/zmsoap"

include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "AuthResponse test"

#
# Setup
#

current.setup = [

]
#
# Execution
#
current.action = [

   v(ZMSoapXml.new('-z', '-m', 'admin', '-t', 'account', 'AuthRequest/account=admin', '@by="name"', "../password=#{Model::DEFAULTPASSWORD}", '../@csrfTokenSecured=1')) do |mcaller, data|
     mcaller.pass = data[0] == 0 && !(data[1].elements['AuthResponse'].get_elements('csrfToken').first.get_text() rescue nil).nil?
  end,

  v(ZMSoapXml.new('-z', '-m', 'admin', '-t', 'account', 'AuthRequest/account=admin', '@by="name"', "../password=#{Model::DEFAULTPASSWORD}", '../@csrfTokenSecured=0')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && (data[1].elements['AuthResponse'].get_elements('csrfToken').first.get_text() rescue nil).nil?
  end,

  v(ZMSoapXml.new('-z', '-m' 'admin', '-t', 'account', 'AuthRequest/account=admin', '@by="name"', "../password=#{Model::DEFAULTPASSWORD}", '../@csrfTokenSecured=10/alpha/')) do |mcaller, data|
    mcaller.pass = data[0] != 0
  end,

  v(ZMSoapXml.new('-z', '-m', 'admin', '-t', 'account', 'AuthRequest/account=admin', '@by="name"', "../password=#{Model::DEFAULTPASSWORD}", '../@csrfTokenWrong=1')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && (data[1].elements['AuthResponse'].get_elements('csrfToken').first.get_text() rescue nil).nil?
  end,

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
