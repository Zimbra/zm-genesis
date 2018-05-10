#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2011 Vmware Zimbra
#
# Test AD GAL search
#
#if($0 == __FILE__)
#  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
#end

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "action/block"
require "action/zmprov"
require "action/verify"
require "model"

include Action

name = 'm' + File.basename(__FILE__,'.rb') + Time.now.to_i.to_s + '.com'

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test AD gal search"

#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [
  ZMProv.new('cd', name,
             'zimbraGalLdapBindDn', 'uid=zimbra,cn=admins,cn=zimbra',
             'zimbraGalLdapBindPassword', 'VOfyG5vic',
             'zimbraGalLdapFilter', '"(cn=%u)"',
             'zimbraGalLdapSearchBase', 'dc=com',
             'zimbraGalLdapURL', 'ldap://zqa-096.eng.zimbra.com:389',
             'zimbraGalMode', 'ldap',
             'zimbraGalLdapGroupHandlerClass', 'com.zimbra.cs.account.grouphandler.ADGroupHandler'),

  v(ZMProv.new('-l', 'syg', name)) do |mcaller,data|
         mcaller.pass = data[0] == 0
  end,
]
#
# Tear Down
#

current.teardown = [
  ZMProv.new('dd', name)
]


if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance
  Engine::Simple.new(Model::TestCase.instance).run
end
