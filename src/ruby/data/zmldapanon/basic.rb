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
# Test zmldapanon
#
#if($0 == __FILE__)
#  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
#end

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "action/block"
require "action/verify"
require "model"
require "action/zmldapanon"
require "action/zmlocalconfig"
require 'net/ldap'

include Action

ldapUrl = ZMLocal.new('ldap_url').run.split(/\s+/)[-1]
zimbraUser = ZMLocal.new('zimbra_ldap_userdn').run
zimbraPassword = ZMLocal.new('zimbra_ldap_password').run

mLdap = Net::LDAP.new(:host => ldapUrl[/ldaps?:\/\/([^:]+).*/, 1],
                      :port => ldapUrl[/ldaps?:\/\/[^:]+:(.*)$/, 1],
                      :auth => {:method => :anonymous},
                      :encryption => ldapUrl =~ /ldaps/ ? {:method => :simple_tls} : nil
                      )

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmldapanon"

#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [
  v(ZMLdapanon.new('help')) do |mcaller,data|
    mcaller.pass = data[0] == 1 && data[1].include?("One of enable or disable must be specified.")\
                                && data[1].include?("Usage: /opt/zimbra/libexec/zmldapanon [-d] [-e]")                                                       
  end,
  
  #zimbra search:    ldapsearch -h `zmhostname` -x -w zimbra -D uid=zimbra,cn=admins,cn=zimbra -b dc=com objectClass=*
  #anonymous search: ldapsearch -h `zmhostname` -x -b dc=com objectClass=*

  v(ZMLdapanon.new('-d')) do |mcaller,data|
    mcaller.pass = data[0] == 0 && data[1].empty?
  end,
  
  v(ZMLdapanon.new('-e')) do |mcaller,data|
    mcaller.pass = data[0] == 0 && data[1].empty?
  end,
    
  v(cb("anonymous search enabled") do
    mLdap.search(:base => 'dc=com',
                 :return_result => true,
                 :filter => Net::LDAP::Filter.eq('objectClass', "*")
                )
  end) do |mcaller, data|
    mcaller.pass = !data.nil? && !data.empty?
  end,
  
  v(ZMLdapanon.new('-d')) do |mcaller,data|
    mcaller.pass = data[0] == 0 && data[1].empty?
  end,
  
  v(cb("anonymous search disabled") do
    mLdap.search(:base => 'dc=com',
                 :return_result => true,
                 :filter => Net::LDAP::Filter.eq('objectClass', "*")
                )
  end) do |mcaller, data|
    mcaller.pass = !data.nil? && data.empty?
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
