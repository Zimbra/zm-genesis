#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2008 Yahoo
#
# zmldappasswd basic test

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "model"
require "action/verify"
require "action/zmldappasswd"
require "action/runcommand"
require "action/zmcontrol"
require "action/zmprov"


#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Zmldappasswd Basic test"


include Action


newPasswd = "test123"

#
# Setup
#
current.setup = [

]

#
# Execution
#
current.action = [

  v(ZMLdapPasswd.new('-h')) do |mcaller, data|
    usage = ['Usage: /opt/zimbra/bin/zmldappasswd [-h] [-r] [-p] [[-c]-l] newpassword',
             "\t-h: display this help message",
             "\t-a: change ldap_amavis_password",
             "\t-b: change ldap_bes_searcher_password",
             "\t-l: change ldap_replication_password",
             "\t-c: Update ldap_replication_password on replica. Requires -l",
             "\t-n: change ldap_nginx_password",
             "\t-p: change ldap_postfix_password",
             "\t-r: change ldap_root_passwd",
             "\tOnly one of a, l, n, p, or r may be specified",
             "\tWithout options zimbra_ldap_password is changed",
             "\tOption -c requires -l and must be run on a replica after",
             "\tchanging the password on the master (using -l by itself)."
             ].collect {|w| Regexp.escape(w)}
    mcaller.pass = data[0] != 0 &&
                   data[1].split(/\n/).delete_if{|w| w =~ /^\s*$/}.select {|w| w !~ /#{usage.join('|')}/}.empty?
  end,
  
  v(ZMLdapPasswd.new('-b', 'zmbes-searcher')) do |mcaller, data|
    usage = ['Updating local config and LDAP']
    mcaller.pass = data[0] == 0 && data[1].split(/\n/).select {|w| w !~ /#{usage.join('|')}/}.empty?
  end,

  v(ZMLdapPasswd.new(newPasswd)) do |mcaller, data|
    mcaller.pass = data[1].include?("Updating local config and LDAP")
  end,

  v(ZMLdapPasswd.new('-r', newPasswd)) do |mcaller, data|
    mcaller.pass = data[1].include?("Updating local config and LDAP")
  end,

  v(ZMLdapPasswd.new('-l', newPasswd)) do |mcaller, data|
    mcaller.pass = data[1].include?("Updating local config and LDAP")
  end,

  v(ZMLdapPasswd.new('-p', newPasswd)) do |mcaller, data|
    mcaller.pass = data[1].include?("Updating local config and LDAP")
  end,

  v(ZMLdapPasswd.new('-a', newPasswd)) do |mcaller, data|
    mcaller.pass = data[1].include?("Updating local config and LDAP")
  end,

  v(ZMControl.new('stop')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?("Stopping")
  end,

  v(ZMControl.new('start')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?("Starting")
  end,
  #Bug 9268 Steps: Modify ldappassrd , restart server , execute zmprov command .....Expected Result:Should not return AUTH_FAILED
  v(ZMProv.new('-l', 'gaa')) do |mcaller, data|
	 mcaller.pass = data[0] == 0 && !data[1].include?("AUTH_FAILED")
  end,
  #END Bug 9268

  v(RunCommand.new('/opt/zimbra/bin/postfix','zimbra','stop')) do |mcaller, data|
        mcaller.pass = data[0] == 0
  end,

  v(RunCommand.new('/opt/zimbra/bin/postfix','zimbra','start')) do |mcaller, data|
     mcaller.pass = data[0] == 0
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
  Engine::Simple.new(Model::TestCase.instance,false).run
end
