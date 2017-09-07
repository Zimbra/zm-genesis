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
# Test zmdomaincertmgr
#
#if($0 == __FILE__)
#  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
#end

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "action/block"
require "action/command"
require "action/clean"
require "action/csearch" 
require "action/zmprov"
require "action/verify"
require "action/runcommand"
require "model"
require "action/zmdomaincertmgr"
require "action/zmcertmgr"

include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmdomaincertmgr"

#
# Setup
#
current.setup = [


]

hash_old = ""
hash_new = ""

#
# Execution
#
current.action = [

   v(ZMDomaincertmgr.new('-help')) do |mcaller,data|
	    mcaller.pass = (data[0] == 1 && data[1].include?("Usage:")\
                                 && data[1].include?("zmdomaincertmgr -help")\
                                 && data[1].include?("zmdomaincertmgr deploycrts")\
                                 && data[1].include?("zmdomaincertmgr savecrt <domain> <cert file> <private key file>")\
                                 && data[1].include?("deploycrts")\
                                 && data[1].include?("savecrt"))                                 
   end,  
   
   #run savecrt with domain foo.com(foo.com domain does not exist) Result: savecrt should fail since foo.com does not exist
   
   v(ZMDomaincertmgr.new('savecrt','foo.com','/opt/zimbra/ssl/zimbra/server/server.crt','/opt/zimbra/ssl/zimbra/server/server.key')) do |mcaller, data|
      mcaller.pass = (data[0] == 0 && data[1].include?("** Saving domain config key zimbraSSLCertificate...failed.")\
                                   && data[1].include?("** Saving domain config key zimbraSSLPrivateKey...failed."))
   end,
     
   
   # Create domain -> do not set zimbraVirtualHostName-> savecrt -> deploycrt Expected: savecrt will pass since domain exists but deploycrts will fail zimbraVirtualHostName is not set
   # Not creating any new domain since using the default domain i.e hostname
   
   v(ZMDomaincertmgr.new('savecrt',Model::TARGETHOST.to_s,'/opt/zimbra/ssl/zimbra/server/server.crt','/opt/zimbra/ssl/zimbra/server/server.key')) do |mcaller, data|
     mcaller.pass = (data[0] == 0 && data[1].include?("** Saving domain config key zimbraSSLCertificate...done.")\
                                  && data[1].include?("** Saving domain config key zimbraSSLPrivateKey...done."))
   end,
  
   v(ZMDomaincertmgr.new('deploycrts'))  do |mcaller,data| mcaller.pass = (data[0] == 1 && data[1].include?("No domains returned by zmprov getAllReverseProxyDomains.")\
                                                                                        && data[1].include?("Consider setting zimbraVirtualHostname.")) #bug 104057
 
   end,
  
   # Create domain -> set zimbraVirtualHostName -> savecrt -> deploycrts Expected: everything should pass
   # Not creating any new domain since using the default domain i.e hostname
   
   v(ZMProv.new('md', Model::TARGETHOST.to_s,'zimbraVirtualHostName',Model::TARGETHOST.to_s)) do |mcaller, data|
      mcaller.pass = data[0] == 0
   end,
    
   v(ZMDomaincertmgr.new('savecrt',Model::TARGETHOST.to_s,'/opt/zimbra/ssl/zimbra/server/server.crt','/opt/zimbra/ssl/zimbra/server/server.key')) do |mcaller, data|
      mcaller.pass = (data[0] == 0 && data[1].include?("** Saving domain config key zimbraSSLCertificate...done.")\
                                   && data[1].include?("** Saving domain config key zimbraSSLPrivateKey...done."))
   end,
   
   v(ZMDomaincertmgr.new('deploycrts'))  do |mcaller,data| mcaller.pass = (data[0] == 0 && data[1].include?("** Deploying cert for "+Model::TARGETHOST+"...done"))

   end,
   
   v(RunCommand.new("sha256sum /opt/zimbra/conf/domaincerts/" +Model::TARGETHOST+".crt"))do |mcaller, data|
     hash_old = data[1].split(" ")[0]
     mcaller.pass = (data[0] == 0)
   end, 
   
   v(ZMCertmgr.new('createcrt', '-new', '-days 365')) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1].include?('** Signing cert request /opt/zimbra/ssl/zimbra/server/server.csr')
   end,  
     
   v(ZMDomaincertmgr.new('savecrt',Model::TARGETHOST.to_s,'/opt/zimbra/ssl/zimbra/server/server.crt','/opt/zimbra/ssl/zimbra/server/server.key')) do |mcaller, data|
      mcaller.pass = (data[0] == 0 && data[1].include?("** Saving domain config key zimbraSSLCertificate...done.")\
                                   && data[1].include?("** Saving domain config key zimbraSSLPrivateKey...done."))
   end,
   
   v(ZMDomaincertmgr.new('deploycrts'))  do |mcaller,data| mcaller.pass = (data[0] == 0 && data[1].include?("** Deploying cert for "+Model::TARGETHOST+"...done"))

   end, 
     
   v(RunCommand.new("sha256sum /opt/zimbra/conf/domaincerts/" +Model::TARGETHOST+".crt"))do |mcaller, data|
      hash_new = data[1].split(" ")[0]
      mcaller.pass = (data[0] == 0 && hash_old != hash_new) # Bug 97981
   end,  
     
   
]
#
# Tear Down
#

current.teardown = [
    ZMProv.new('md', Model::TARGETHOST.to_s,'zimbraVirtualHostName'," ","\"\"") #unset zimbraVirtualHostName 
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance
  Engine::Simple.new(Model::TestCase.instance).run
end
