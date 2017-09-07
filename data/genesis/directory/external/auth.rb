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
# Test external auth
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
require "action/zmmailbox"
require "model"


#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test external ldap auth"

include Action

name = File.expand_path(__FILE__).sub(/.*?(data\/)(genesis\/)?(zm)?/, 'zm').sub('.rb', '').gsub(/\/|\(|\)/, '')
mDomain = Model::Domain.new(name + Time.now.to_i.to_s + '.com')
mAccountOne = mDomain.cUser(name + Time.now.to_i.to_s + "1")
mAccountTwo = mDomain.cUser(name + Time.now.to_i.to_s + "2")
mAccountThree = mDomain.cUser(name + Time.now.to_i.to_s + "3")

def genVerifyMessages(targetLog, tailLines, accountName, expectedMessage, occurrences)
  Verify.new(RunCommand.new('grep', 'root', "#{accountName}", targetLog)) do |mcaller, data|   
    mcaller.pass = data[0] == 0 && 
                   data[1].split(/\n/).select {|w| w =~ /#{expectedMessage}/}.length == occurrences
  end  
end

#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [
  # zmprov cd ext.auth.com
  # zmprov md ext.auth.com zimbraAuthLdapURL "ldap://zqa-003.eng.vmware.com:389" zimbraAuthLdapBindDn "%u@xxx.com" zimbraAuthMech ad
  ZMProv.new('cd', mDomain.name, 
             'zimbraAuthLdapURL', "ldap://zqa-003.eng.vmware.com:389",
             'zimbraAuthLdapBindDn', "%u@foo.com",
             'zimbraAuthLdapSearchFilter', "\"(cn=%u)\""),           
  # zmprov ca t1@ext.auth.com test123
  ZMProv.new('ca', mAccountOne.name, Model::DEFAULTPASSWORD),
  
  # enable account logging for the account
  ZMProv.new('addAccountLogger', mAccountOne.name, 'zimbra.account', 'debug'),

  # check logged messages
  ZMMail.new('-m', mAccountOne.name, '-p', Model::DEFAULTPASSWORD, 'sm'),
  genVerifyMessages('/opt/zimbra/log/mailbox.log', 20, mAccountOne.name, "authentication failed for \\[#{mAccountOne.name}\\]", 0),


  # zimbraAuthMech ad
  ZMProv.new('md', mDomain.name, 'zimbraAuthMech ad'),
  ZMProv.new('ca', mAccountTwo.name, Model::DEFAULTPASSWORD),
  ZMProv.new('addAccountLogger', mAccountTwo.name, 'zimbra.account', 'debug'),  
  # check logged messages
  ZMMail.new('-m', mAccountTwo.name, '-p', Model::DEFAULTPASSWORD, 'sm'),
  genVerifyMessages('/opt/zimbra/log/mailbox.log', 20, mAccountTwo.name,
                    "auth with bind dn template of #{mAccountTwo.name[/([^@]+)/, 1]}@foo.com", 1),

  # zimbraAuthMech ldap
  ZMProv.new('md', mDomain.name, 'zimbraAuthMech ldap'),
  ZMProv.new('ca', mAccountThree.name, Model::DEFAULTPASSWORD),
  ZMProv.new('addAccountLogger', mAccountThree.name, 'zimbra.account', 'debug'),
  # check logged messages
  ZMMail.new('-m', mAccountThree.name, '-p', Model::DEFAULTPASSWORD, 'sm'),
  genVerifyMessages('/opt/zimbra/log/mailbox.log', 20, mAccountThree.name,
                    "auth with search filter of \\(cn=#{mAccountThree.name[/([^@]+)/, 1]}\\)", 1),

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
