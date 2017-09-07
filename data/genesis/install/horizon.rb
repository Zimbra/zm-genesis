#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2011 VMWare
#
# Horizon lab hookup
#
# This script should be used only for zqa-065.eng.vmware.com (current). 
#
if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model" 
require "action/block"
require 'action/runcommand'
require "action/zmcontrol"
require "action/zmprov"
require "action/verify"
 

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Horizon Integration"

include Action 

langDump = []

  
 
#
# Setup
#
current.setup = [
  
]
trione = Model::TARGETHOST.cUser("testsamlsso", Model::DEFAULTPASSWORD)
#
# Execution
#
current.action = 
  [ 
   ZMProv.new('md', Model::TARGETHOST, '+zimbraForeignName', 'tricipherCompanyName:ZIMBRATEST'),
   ZMProv.new('md', Model::TARGETHOST, '+zimbraForeignNameHandler', 'tricipherSaml:com.zimbra.cs.security.tricipher.TriCipherSamlNameMapper'),
   ZMProv.new('md', Model::TARGETHOST, 'zimbraWebClientLoginURL', 'https://zimbratest.horizonlabs.vmware.com/SAAS/API/1.0/GET/apps/launch?aid=844'),
   ZMProv.new('md', Model::TARGETHOST, 'zimbraWebClientLogoutURL', 'https://zimbratest.horizonlabs.vmware.com/'),
   RunCommand.new('/bin/env', Command::ZIMBRAUSER, 'wget', '--no-proxy',
                  '-O', '/opt/zimbra/conf/horcert.txt',
                  "http://zqa-tms/files/horcert.txt"),
   RunCommand.new('/bin/env', Command::ZIMBRAUSER, 'wget', '--no-proxy',
                  '-O', '/var/tmp/horcert.sh',
                  "http://zqa-tms/files/horcert.sh"),
   RunCommand.new('bash', Command::ZIMBRAUSER, '-x', '/var/tmp/horcert.sh', Model::TARGETHOST),
   CreateAccount.new(trione, 'test123'),
   ZMProv.new('ma', trione.name, '+zimbraForeignPrincipal', 'tricipherSaml:admin'),
   Action::RunCommand.new('mkdir','root', '/opt/zimbra/lib/ext/tricipher'),
   Action::RunCommand.new('chown', 'root', 'zimbra:zimbra /opt/zimbra/lib/ext/tricipher'),
   Action::RunCommand.new('cp', 'root', '/opt/zimbra/extensions-network-extra/saml/myonelogin/*',
                          '/opt/zimbra/lib/ext/tricipher'),
   ZMControl.new('restart')
]

#
# Tear Down
#
current.teardown = [      
 
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance, false).run  
end 
