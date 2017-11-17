#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2010 VMWare
#
# zmprov dynamic list basic test

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 

require "model"
require "action/block"
require "action/zmprov" 
require "action/verify"
require "action/zmlocalconfig"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Zmprov Dynamic List Basic test"

name = File.expand_path(__FILE__).sub(/.*?(data\/)(genesis\/)?(zm)?/, 'zm').sub('.rb', '').gsub(/\/|\(|\)/, '') + Time.now.to_i.to_s
testAccount = Model::TARGETHOST.cUser(name+'1', Model::DEFAULTPASSWORD)
testAccountTwo = Model::TARGETHOST.cUser(name+'2', Model::DEFAULTPASSWORD)
testAccountThree = Model::TARGETHOST.cUser(name+'3', Model::DEFAULTPASSWORD)
testAccountFour = Model::TARGETHOST.cUser(name+'4', Model::DEFAULTPASSWORD)
testAccountFive = Model::TARGETHOST.cUser(name+'5', Model::DEFAULTPASSWORD)

include Action

#
# Setup
#
current.setup = [

]

#
# Execution
#
current.action = [
  # createDynamicDistributionList(cddl) {list@domain}
  v(ZMProv.new('cddl',testAccount)) do |mcaller, data|	
    mcaller.pass = data[0] == 0
  end,
  v(ZMProv.new('cddl')) do |mcaller, data|  
    mcaller.pass = data[0] != 0
  end,
  
  # getDistributionList(gdl) {list@domain|id} [attr1 [attr2...]]
  v(ZMProv.new('gdl', testAccount)) do |mcaller, data|
    mId=data[1][/zimbraId:\s+(\S+)/, 1]
    mDgId = ZMLocal.new('zimbra_ldap_userdn').run
    mcaller.pass = data[0] == 0 && 
                   data[1].include?('objectClass: groupOfURLs') &&
                   data[1].include?('objectClass: dgIdentityAux') &&
                   data[1].include?("memberURL: ldap:///??sub?(|(zimbraMemberOf=#{mId})") &&
                   data[1].include?("dgIdentity: #{mDgId}")
  end,
  #TODO
  #gdl id
  #gdl list@domain attr1
  #gdl list@domain attr+
  
  # addDistributionListAlias(adla) {list@domain|id} {alias@domain}
  v(ZMProv.new('adla',testAccount, testAccountTwo)) do |mcaller, data|	
    mcaller.pass = data[0] == 0
  end,
  #TODO
  #adla id alias@domain
  #adla
  #adla list@domain alias
  #adla alias@domain

  # addDistributionListMember(adlm) {list@domain|id} {member@domain}+
  v(ZMProv.new('CreateAccount', testAccountThree.name, testAccountThree.password)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  #addDistributionListMember(adlm) {list@domain|id} {member@domain}+
  v(ZMProv.new('adlm', testAccount, testAccountThree)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  # adlm list1@domain list2@domain
  v(ZMProv.new('cddl',testAccountFour)) do |mcaller, data|  
    mcaller.pass = data[0] == 0
  end,
  v(ZMProv.new('adlm', testAccountFour, testAccount)) do |mcaller, data|
    mcaller.pass = data[0] != 0 && 
                   data[1] =~ /^ERROR: service.INVALID_REQUEST\s+\(invalid request: address cannot be a group: \[#{testAccount.name}\]\)$/
  end,
  #TODO
  #adlm list@domain member member
  #adlm list@domain
  #adlm list member
  #adlm id
  #adlm id member
  
  # getAllDistributionLists(gadl) [-v] [{domain}]
  v(ZMProv.new('gadl')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].split(/\n/).include?(testAccountFive.name)
  end,
  #TODO
  #gadl domain
  #gadl list/mmember
  
  v(ZMProv.new('cddl', testAccountFive.name)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  #deleteDistributionList(ddl) {list@domain|id}
  v(ZMProv.new('ddl', testAccountFive.name)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  v(ZMProv.new('ddl')) do |mcaller, data|
    mcaller.pass = data[0] != 0
  end,
  #TODO
  #ddl id
  #ddl list
  #ddl member@domain
  #ddl non-emptylist
  
  # getAccountMembership(gam) {name@domain|id}
  v(ZMProv.new('gam', testAccountThree)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].split(/\n/) == [testAccount.name]
  end,
  #TODO
  #gam id
  #gam dlid
  #gam name
  #gam name@foo.com
  
  v(ZMProv.new('cddl', testAccountFive.name, 
               'memberURL', '"ldap:///??sub?(objectClass=zimbraAccount)"')) do |mcaller, data|
    mcaller.pass = data[0] != 0 &&
                   data[1] =~ /^ERROR: ldap.OBJECT_CLASS_VIOLATION/
  end,
  v(ZMProv.new('cddl', testAccountFive.name, 
               'memberURL', '"ldap:///??sub?(objectClass=zimbraAccount)"',
               'zimbraIsACLGroup', 'FALSE')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  v(ZMProv.new('ddl', testAccountFive.name)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,

  # getDistributionListMembership(gdlm) {name@domain|id}
  v(ZMProv.new('gdlm',testAccount)) do |mcaller, data|  
    mcaller.pass = data[0] == 0 && data[1].include?("distributionList " + testAccount.name + " memberCount=1")
  end,
  v(cb("gdlm id") do
    mId = ZMProv.new('cddl', testAccountFive.name).run[1].chomp
    ZMProv.new('gdlm', mId).run
  end) do |mcaller, data|  
    mcaller.pass = data[0] == 0 && data[1].include?("distributionList " + testAccountFive.name + " memberCount=0")
  end,

  # modifyDistributionList(mdl) {list@domain|id} attr1 value1 [attr2 value2...]
  v(ZMProv.new('mdl', testAccount, 'zimbraHideInGal', 'TRUE')) do |mcaller, data|  
    mcaller.pass = data[0] == 0
  end,
  v(cb("mdl id") do
    mId = ZMProv.new('gdl', testAccount.name).run[1][/zimbraId: (\S+)/, 1]
    ZMProv.new('mdl', mId, 'zimbraHideInGal', 'FALSE').run
  end) do |mcaller, data| 
    mcaller.pass = data[0] == 0
  end,
  
  # removeDistributionListAlias(rdla) {list@domain|id} {alias@domain}

  # removeDistributionListMember(rdlm) {list@domain|id} {member@domain}
  v(ZMProv.new('rdlm', testAccount, testAccountThree)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  #TODO:
  #rdlm id member@domain
  #rdlm list@domain
  #rdlm list
  #rdlm id
  #rdlm
  
  # renameDistributionList(rdl) {list@domain|id} {newName@domain}
  v(ZMProv.new('ddl', testAccountFive.name)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  v(ZMProv.new('rdl', testAccount.name, testAccountFive.name)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  #TODO:
  #rdl id newName@domain
  #rdl list@domain
  #rdl id
  #rdl
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