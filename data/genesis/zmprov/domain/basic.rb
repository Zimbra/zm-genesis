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
# zmprov domain basic test

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "model"
require "action/zmprov"
require "action/verify"


#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Zmprov Domain Basic test"


include Action

name = 'zmprov'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
domainname = 'domain'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s+'.com'
subdomainname = 'sub.'+domainname
dl1 = 'dl@'+domainname
ddl1 = 'dyngroup@'+domainname
dl2 = 'dl@'+subdomainname
ddl2 = 'dyngroup@'+subdomainname

#
# Setup
#
current.setup = [

]

#
# Execution
#
current.action = [
  #Create domain
  v(ZMProv.new('cd','testdomain.what.com')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,

  # Get all domain
  v(ZMProv.new('gad')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('testdomain.what.com')
  end,

  # Get domain
  v(ZMProv.new('gd', Model::TARGETHOST.to_s)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('objectClass: zimbraDomain') &&
    data[1].include?('zimbraDomainName: '+ Model::TARGETHOST)
  end,

  # Modify domain
  v(ZMProv.new('md', 'testdomain.what.com', 'zimbraMailStatus', 'disabled')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,


  # create alias domain
  v(ZMProv.new('cad', 'testdomain-alias.what.com','testdomain.what.com')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,

  # Get domain
  v(ZMProv.new('gd', 'testdomain-alias.what.com')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('objectClass: zimbraDomain') &&
    data[1].include?('zimbraDomainName: '+ 'testdomain-alias.what.com') && data[1].include?('zimbraDomainType: alias')
  end,

  # Get domain
  v(ZMProv.new('gd', Model::TARGETHOST.to_s)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('objectClass: zimbraDomain') &&
    data[1].include?('zimbraDomainName: '+ Model::TARGETHOST)
  end,

  # Delete domain
  v(ZMProv.new('dd','testdomain-alias.what.com')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,

  # Get domain
  v(ZMProv.new('gd', Model::TARGETHOST.to_s)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('objectClass: zimbraDomain') &&
    data[1].include?('zimbraDomainName: '+ Model::TARGETHOST)
  end,

  # Get domain
  v(ZMProv.new('gd', 'testdomain-alias.what.com')) do |mcaller, data|
    mcaller.pass = data[0] == 2 && data[1].include?('NO_SUCH_DOMAIN')
  end,

  # Rename domain # Not possibel from here to be done from LDAP? CLI says.
  v(ZMProv.new('-l', 'rd','testdomain.what.com','testdomain.what.net'), 300) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,


  # Delete domain
  v(ZMProv.new('dd','testdomain.what.net')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
	
  # Bug 35336
  v(ZMProv.new('-d','cd','other1.testdomain.com')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].include?("User-Agent")\
                                && data[1].include?("SOAP SEND")\
                                && data[1].include?("SOAP RECEIVE")\
                                && data[1].include?("CreateDomainRequest")\
                                && data[1].include?("CreateDomainResponse")
  end,	
  v(ZMProv.new('-D','cd','other2.testdomain.com')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?("User-Agent")\
                                && data[1].include?("SOAP SEND")\
                                && data[1].include?("SOAP RECEIVE")\
                                && data[1].include?("CreateDomainRequest")\
                                && data[1].include?("CreateDomainResponse")
  end,	
  v(ZMProv.new('dd','other1.testdomain.com')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  v(ZMProv.new('dd','other2.testdomain.com')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  #END Bug 35336
  
  # Bug 66001
  v(ZMProv.new('cd',domainname)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  
  v(ZMProv.new('md', domainname, 'zimbraGalInternalSearchBase', 'DOMAIN')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  
  v(ZMProv.new('cdl',dl1)) do |mcaller, data| 
    mcaller.pass = data[0] == 0
  end,  
  
  v(ZMProv.new('cddl',ddl1)) do |mcaller, data|  
    mcaller.pass = data[0] == 0
  end,

  v(ZMProv.new('cd',subdomainname)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  
  v(ZMProv.new('cdl',dl2)) do |mcaller, data| 
    mcaller.pass = data[0] == 0
  end,  
  
  v(ZMProv.new('cddl',ddl2)) do |mcaller, data|  
    mcaller.pass = data[0] == 0
  end,
  
  v(ZMProv.new('-l','syg',domainname)) do |mcaller, data| 
    mcaller.pass = data[0] == 0  && !data[1].include?(dl2)\
                                 && !data[1].include?(ddl2)\
                                 && data[1].include?(dl1)\
                                 && data[1].include?(ddl1)
  end,
  #END Bug 66001

]
#
# Tear Down
#
current.teardown = [

]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance
  Engine::Simple.new(Model::TestCase.instance, true).run
end