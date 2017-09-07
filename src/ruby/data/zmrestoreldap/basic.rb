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
# Test zmrestoreldap
#
#if($0 == __FILE__)
#  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
#end

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "action/command"
require "action/clean"
require "action/block"
require "action/zmprov"
require "action/verify"
require "action/runcommand"
require "model"
require "action/zmrestoreldap"
require "action/zmcontrol"
require "action/ldap"
require "action/zmbackup"
require "action/waitqueue"
require "action/zmlicense"
require "action/zmrestoreldap"
require "action/zmlocalconfig"
require "action/sendmail"

include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmrestoreldap"
nameString = 'user'+Time.now.to_i.to_s
removeLicense = "/tmp/removeLicense.ldif"
countOfAccounts = 0
newLicenseLimit = 0
ldapPassword = RunCommand.new('/opt/zimbra/bin/zmlocalconfig', 'zimbra','-s', '|', 'grep', 'ldap_root_password')
nNow = Time.now.to_i.to_s
nMount = File.join(Command::ZIMBRAPATH, 'restoreldap'+nNow)
nTmpMount = File.join(ZMLocal.new('-x', 'zimbra_tmp_directory').run, nNow)
numberOfUser = 10
nameString = 'restoreldap'+Time.now.to_i.to_s

fullbackup = Action::Fullbackup.new('-a','all','-t',nMount)

#.gsub(/\n/,  "\r\n")
message = <<EOF
dn: cn=config,cn=zimbra
changetype: modify
delete: zimbraNetworkLicense
EOF
#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [
  # create ldif file to delete license
 RunCommand.new('/bin/echo', 'zimbra', '"',  message, '"',  ">", removeLicense),

  v(ZMRestoreLDAP.new('-h'))do|mcaller,data|
   mcaller.pass = data[0]==1 && data[1].include?('Usage')
  end,

  v(ZMRestoreLDAP.new('--help'))do|mcaller,data|
   mcaller.pass = data[0]==1 && data[1].include?('Usage')
  end,

# Bug 33415
#  v(ZMRestoreLDAP.new('-lb','wrong'))do|mcaller,data|
#   mcaller.pass = data[0]==0 && data[1].include?('Usage')
#  end,



  RunCommand.new('/bin/mkdir','root',nMount),
  RunCommand.new('/bin/chown','root','zimbra', nMount),
  RunCommand.new('/bin/chgrp','root','zimbra', nMount),

  Action::ZMProv.new('ms '+ Model::TARGETHOST+ '  zimbraBackupTarget ' + nMount),
  #Create Accounts
  CreateAccounts.new(nameString, Model::TARGETHOST, numberOfUser, Model::DEFAULTPASSWORD),
=begin
  #Send emails
  cb("Send Emails", 600) do
    1.upto(numberOfUser) do |x|
      address = Model::TARGETHOST.cUser("#{nameString}#{x}", Model::DEFAULTPASSWORD)
      outMessage = message.gsub(/REPLACEME/,address.name).gsub(/MARKINDEX/, address.name)
      Action::SendMail.new(address.name, outMessage).run
    end
  end,
  #Wait a bit for system to finish
  WaitQueue.new,

  fullbackup,

  ldapPassword,

  v(LdapModify.new('-h', Model::TARGETHOST, '-x', '-D', '"cn=config"', '-w', ldapPassword.run[1].match(/ldap_root_password = (.*)/)[1], '-f', removeLicense))do |mcaller,data|
    mcaller.pass = data[0] == 0 && data[1].include?('modifying entry')
  end,

  v(LdapSearch.new('-h', Model::TARGETHOST, '-x','-LLL', '-D', '"cn=config"', '-w', ldapPassword.run[1].match(/ldap_root_password = (.*)/)[1],'"(objectClass=zimbraGlobalConfig)"', 'zimbraNetworkLicense'))do |mcaller,data|
    mcaller.pass = data[0] == 0 && !data[1].include?('zimbraNetworkLicense::')
  end,

  v(ZMLicense.new('-p')) do |mcaller, data|
    mcaller.pass = (data[0] == 1)&& data[1].include?('license is not installed')
  end,

  v(ZMRestoreLDAP.new('-lb',fullbackup.clabel,'-t',nMount))do|mcaller,data|
   mcaller.pass = data[0]==0
  end,

  v(LdapSearch.new('-h', Model::TARGETHOST, '-x','-LLL', '-D', '"cn=config"', '-w', ldapPassword.run[1].match(/ldap_root_password = (.*)/)[1],'"(objectClass=zimbraGlobalConfig)"', 'zimbraNetworkLicense'))do |mcaller,data|
    mcaller.pass = data[0] == 0 && data[1].include?('zimbraNetworkLicense::')
  end,

  v(ZMLicense.new('-c')) do |mcaller, data|
    mcaller.pass = (data[0] == 0)&& data[1].include?('OK')
  end,

  Action::ZMProv.new('ms ', Model::TARGETHOST, '  zimbraBackupTarget','/opt/zimbra/backup' ),

  v(ZMRestoreLDAP.new('-lb',fullbackup.clabel,'-t',nMount, '-lbs'))do|mcaller,data|
   mcaller.pass = data[0]==0 && data[1].include?('full')
  end,

  v(ZMRestoreLDAP.new('-lb',fullbackup.clabel,'-t',nMount, '-l'))do|mcaller,data|
   mcaller.pass = data[0]==0 && data[1].include?('restoreldap')
  end,

  v(ZMRestoreLDAP.new('-lb',fullbackup.clabel,'-t',nMount, '-a',nameString+'1@'+ Model::TARGETHOST))do|mcaller,data|
   mcaller.pass = data[0]==0 && data[1].include?('ldap_add: Already exists')
  end,

  v(ZMProv.new('da',nameString+'1@'+ Model::TARGETHOST))do |mcaller, data|
    mcaller.pass = data[0]==0
  end,

  v(ZMRestoreLDAP.new('-lb',fullbackup.clabel,'-t',nMount, '-a',nameString+'1@'+ Model::TARGETHOST))do|mcaller,data|
   mcaller.pass = data[0]==0 && data[1].include?('ldap_initialize')
  end,
=end
# Bug 33415 Start
  v(ZMRestoreLDAP.new('-lb', 'full.111111'))do|mcaller,data|
   mcaller.pass = data[0] != 0 && data[1].include?('Error: No backup file found for main database')
  end,
=begin
  v(ZMControl.new('restart'))do | mcaller,data|
   mcaller.pass = data[0] == 0 && !data[1].include?('failed')
  end,  
# Bug 33415 End

# Bug 50316
  v(ZMRestoreLDAP.new('-lbs'))do|mcaller,data|
   mcaller.pass = data[0]==0 && !data[1].include?('variable')
  end,
# End Bug 50316
=end
  v(ZMRestoreLDAP.new('-h'))do|mcaller,data|
    mcaller.pass = data[0] != 0 && data[1].include?('zmrestoreldap -o <directory> <options>')
  end,
  
  v(ZMRestoreLDAP.new('-o'))do|mcaller,data|
    mcaller.pass = data[0] != 0 && data[1].include?('Option o requires an argument')
  end,

  v(ZMRestoreLDAP.new('-o', mPath = '/foo/blah'))do|mcaller,data|
    mcaller.pass = data[0] != 0 && data[1].include?('Error: No backup file found for main database: ' + File.join(mPath, 'ldap.bak'))
  end,
  
  RunCommand.new('libexec/zmbackupldap', Command::ZIMBRAUSER, '--outdir', nTmpMount),
  
  v(ZMRestoreLDAP.new('-o', nTmpMount, '-lbs')) do |mcaller,data|
    mcaller.pass = data[0] != 0 && data[1].include?('Usage: zmrestoreldap')
  end,
  
  v(ZMRestoreLDAP.new('-o', nTmpMount, '-l')) do |mcaller,data|
    mcaller.pass = data[0] == 0 && data[1].split(/\n/).select {|w| w =~ /#{nameString}/}.size == numberOfUser
  end,
  
  v(ZMRestoreLDAP.new('-o', nTmpMount, '-a',nameString+'2@'+ Model::TARGETHOST)) do |mcaller,data|
    mcaller.pass = data[0] == 0 && data[1].include?('ldap_add: Already exists')
  end,
  
  v(ZMProv.new('da',nameString+'2@'+ Model::TARGETHOST))do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  
  v(ZMRestoreLDAP.new('-o', nTmpMount, '-a',nameString+'2@'+ Model::TARGETHOST)) do |mcaller,data|
    mcaller.pass = data[0] == 0 && data[1].include?('ldap_initialize')
  end,

=begin
 ZMControl.new('stop'),
 ZMControl.new('start'),
=end
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
