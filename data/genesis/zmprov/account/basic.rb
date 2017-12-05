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
# zmprov account basic test

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "model"
require "action/zmprov"
require "action/block"
require "action/soap/login"
require "action/verify"
require "action/json/login"
require 'model/json/loginrequest'
require 'action/zmmailbox'


#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Zmprov Account Basic test"


include Action

name = File.expand_path(__FILE__).sub(/.*?(data\/)(genesis\/)?(zm)?/, 'zm').sub('.rb', '').gsub(/\/|\(|\)/, '') + Time.now.to_i.to_s
testAccount = Model::TARGETHOST.cUser(name+'1', Model::DEFAULTPASSWORD)
testAccountChanged = Model::TARGETHOST.cUser(name+'1', 'whatever')
testAccountTwo = Model::TARGETHOST.cUser(name+'2', Model::DEFAULTPASSWORD)
renamedAccount = Model::TARGETHOST.cUser(name+'3', Model::DEFAULTPASSWORD)
testAccountThree = Model::TARGETHOST.cUser(name+'4', 'p') # Invalid Password bug 30125
testAccountFour = Model::TARGETHOST.cUser(name+'5', Model::DEFAULTPASSWORD)
testAccountFive = Model::TARGETHOST.cUser(name+'6', Model::DEFAULTPASSWORD)
testAccountSix = Model::TARGETHOST.cUser(name+'7', Model::DEFAULTPASSWORD)
testAccountSeven = Model::TARGETHOST.cUser(name+'8', Model::DEFAULTPASSWORD)
adminAccount = Model::TARGETHOST.cUser('admin', Model::DEFAULTPASSWORD)

cidattribute = ['zimbraPrefForwardIncludeOriginalText', 'includeBody']
sigId1 = nil

#
# Setup
#
current.setup = [
]

#
# Execution
#
current.action = [
  #Create Account
  v(ZMProv.new('ca', testAccount.name, testAccount.password)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  v(ZMProv.new('CreateAccount', testAccountTwo.name, testAccountTwo.password)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  #Get Account
  v(ZMProv.new('ga', testAccount.name)) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && (data[1].include?(testAccount.name))
  end,
  v(ZMProv.new('GetAccount', testAccountTwo.name)) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && (data[1].include?(testAccountTwo.name)) && data[1].include?("zimbraJunkMessagesIndexingEnabled: TRUE")
  end,

  v(ZMProv.new('ca', testAccountThree.name, testAccountThree.password)) do |mcaller, data|
    mcaller.pass = data[0] == 2 && data[1].include?("invalid password: too short")
  end,
  v(ZMProv.new('CreateAccount', testAccountThree.name, testAccountThree.password)) do |mcaller, data|
    mcaller.pass = data[0] == 2 && data[1].include?("invalid password: too short")
  end,
  v(ZMProv.new('ga', testAccountThree.name)) do |mcaller, data|
    mcaller.pass = data[0] == 2 && data[1].include?("no such account:")
  end,
  v(ZMProv.new('GetAccount', testAccountThree.name)) do |mcaller, data|
    mcaller.pass = data[0] == 2 && data[1].include?("no such account:")
  end,

  #Get All Accounts
  v(ZMProv.new('-l', 'gaa')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && [testAccount, testAccountTwo, adminAccount].all? do |x|
                   data[1].include?(x)
    end
  end,
  v(ZMProv.new('-l','GetAllAccounts')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && [testAccount, testAccountTwo, adminAccount].all? do |x|
                   data[1].include?(x)
    end
  end,
  v(ZMProv.new('-l', 'gaa', '-v')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && [testAccount, testAccountTwo, adminAccount].all? do |x|
                   data[1].include?(x) end &&
                   data[1].include?('userPassword')
  end,
  #Get All Admin Accounts
  v(ZMProv.new('gaaa')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?(adminAccount) && [testAccount, testAccountTwo].all? do |x|
                   !data[1].include?(x)
    end
  end,
  v(ZMProv.new('gaaa', '-v')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?(adminAccount) && [testAccount, testAccountTwo].all? do |x|
                   !data[1].include?(x) end &&
                   data[1].include?('postmaster')
  end,
  # ModifyAccount
  v(ZMProv.new('ma', testAccount, 'zimbraPrefSaveToSent', 'FALSE')) do |mcaller, data|
    isSet = ZMProv.new('ga', testAccount).run[1]
    mcaller.pass = (data[0] == 0) && isSet.include?('zimbraPrefSaveToSent: FALSE')
  end,
  # Rename Account
  v(ZMProv.new('ra', testAccount, renamedAccount)) do |mcaller, data|
    isSet = ZMProv.new('-l', 'gaa').run[1]
    mcaller.pass = data[0] == 0 && isSet.include?(renamedAccount) && !isSet.include?(testAccount)
  end,
  v(ZMProv.new('ra', renamedAccount, testAccount)) do |mcaller, data|
    isSet = ZMProv.new('-l', 'gaa').run[1]
    mcaller.pass = data[0] == 0 && isSet.include?(testAccount) && !isSet.include?(renamedAccount)
  end,
  # Set Account Cos
  v(ZMProv.new('cc', 'testcos')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  v(ZMProv.new('sac', testAccount, 'testcos')) do |mcaller, data|
    isSet = ZMProv.new('ga', testAccount).run[1]
    #puts YAML.dump(isSet)
    mcaller.pass = data[0] == 0
  end,
  v(ZMProv.new('dc', 'testcos')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  # Set Password
  v(ZMProv.new('sp', testAccount, testAccountChanged.password)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  v(Json::Login.new(Model::Json::LoginRequest.new(testAccountChanged))) do |mcaller, data|
    mcaller.pass = !data.nil?
  end,
  # Remove Account Alias
  v(ZMProv.new('raa',testAccount, testAccountTwo)) do |mcaller, data|
    mcaller.pass = data[1].include?('no such alias')
  end,
  # Make sure testAccountTwo still exist after raa
  v(ZMProv.new('GetAccount', testAccountTwo.name)) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && (data[1].include?(testAccountTwo.name))
  end,
  # Make sure aaa doesn't work on existing account
  v(ZMProv.new('aaa',testAccount, testAccountTwo)) do |mcaller, data|
    mcaller.pass = data[1].include?('ACCOUNT_EXISTS')
  end,
  # and account still exist afterward
  v(ZMProv.new('GetAccount', testAccountTwo.name)) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && (data[1].include?(testAccountTwo.name))
  end,
  # Get Membership
  v(ZMProv.new('gam',testAccount)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  # Create Identity
  v(ZMProv.new('-z', 'cid', testAccount, 'testidentity', *cidattribute)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  v(ZMProv.new('-z', 'gid', testAccount, 'testidentity')) do |mcaller, data|
    mcaller.pass = data[1].include?('testidentity')
  end,
  # Create Signature
  v(ZMProv.new('csig', testAccount, 'testsignature1')) do |mcaller, data|
    sigId1 = data[1].chomp
    mcaller.pass = data[0] == 0 && data[1] =~ /^[\da-f\-]{36}$/
  end,
  v(ZMProv.new('gsig', testAccount)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1] =~ /zimbraSignatureName:\s+testsignature1\s*$/ &&
                   data[1] =~ /zimbraSignatureId:\s+#{sigId1}\s/
  end,
  v(ZMProv.new('ga', testAccount, 'zimbraPrefDefaultSignatureId')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1] =~ /zimbraPrefDefaultSignatureId:\s+#{sigId1}\s*$/
  end,
  v(ZMProv.new('csig', testAccount, 'testsignature2')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1] =~ /^[\da-f\-]{36}$/
  end,
  v(ZMProv.new('ga', testAccount, 'zimbraPrefDefaultSignatureId')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1] =~ /zimbraPrefDefaultSignatureId:\s+#{sigId1}\s*$/
  end,
  v(ZMProv.new('dsig', testAccount, 'testsignature1')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].empty?
  end,
  v(ZMProv.new('ga', testAccount, 'zimbraPrefDefaultSignatureId')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].include?('zimbraPrefDefaultSignatureId')
  end,
  # create data source
  v(ZMProv.new('cds', testAccount,'pop3','testds','zimbraDataSourceConnectionType','cleartext',
               'zimbraDataSourceEmailAddress','zimbraqa01@yahoo.in','zimbraDataSourceEnabled','TRUE','zimbraDataSourceFolderId',
    ZMProv.new('sm',testAccount,'cf','/testds').run[1].match(/\d{3}/),'zimbraDataSourceHost','in.pop.mail.yahoo.com',
               'zimbraDataSourceLeaveOnServer','TRUE','zimbraDataSourcePollingInterval','0','zimbraDataSourcePort','110',
               'zimbraDataSourceUsername','zimbraqa01','zimbraDataSourcePassword','test123456')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  # check if data source created
  v(ZMProv.new('gds', testAccount)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('testds')
  end,
  v(ZMProv.new('mds', testAccount,'testds','zimbraDataSourcePassword','test123')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  # delete data source
  v(ZMProv.new('dds', testAccount, 'testds')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  # check if data source deleted
  v(ZMProv.new('gds', testAccount)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].include?('testds')
  end,
  v(ZMProv.new('cps', testAccountTwo.name,'aaa')) do |mcaller, data|
    mcaller.pass = data[0] == 2 && data[1].include?('too short')
  end,
  v(ZMProv.new('checkPasswordStrength', testAccountTwo.name,'aaa')) do |mcaller, data|
    mcaller.pass = data[0] == 2 && data[1].include?('too short')
  end,
  v(ZMProv.new('cps', testAccountTwo.name,'test123')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('passed strength check')
  end,
  v(ZMProv.new('checkPasswordStrength', testAccountTwo.name,'test123')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('passed strength check')
  end,
  #zmprov csig admin@`zmhostname` testsig3 zimbraPrefMailSignature "test signature\\n test"
  v(ZMProv.new('csig', testAccountTwo.name,'testsig1','zimbraPrefMailSignature','"Test Signature"')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  v(ZMProv.new('createSignature', testAccountTwo.name,'testsig2','zimbraPrefMailSignature','"Test Signature"')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  v(ZMProv.new('getSignatures', testAccountTwo.name)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('testsig1') && data[1].include?('testsig2')
  end,
  v(ZMProv.new('gsig', testAccountTwo.name)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('testsig1') && data[1].include?('testsig2')
  end,
  v(ZMProv.new('msig', testAccountTwo.name,'testsig1','zimbraPrefMailSignature','"Test Signature1 Modified"')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  v(ZMProv.new('modifySignature', testAccountTwo.name,'testsig2','zimbraPrefMailSignature','"Test Signature2 Modified"')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  v(ZMProv.new('gsig', testAccountTwo.name)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('Test Signature1 Modified') && data[1].include?('Test Signature2 Modified')
  end,
  v(ZMProv.new('dsig', testAccountTwo.name,'testsig1')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  v(ZMProv.new('deleteSignature', testAccountTwo.name,'testsig2')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  v(ZMProv.new('gsig', testAccountTwo.name)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].include?('Test Signature1 Modified') && !data[1].include?('Test Signature2 Modified')
  end,
  v(ZMProv.new('cta', Model::TARGETHOST.to_s)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('# of accounts')
  end,
  #Test create, modify, get, delete Identities
  v(ZMProv.new('createIdentity', testAccount, 'testID1')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].include?('ERROR')
  end,
  v(ZMProv.new('cid', testAccount, 'testID2', 'zimbraPrefReplyToAddress', testAccountTwo)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].include?('ERROR')
  end,
  v(ZMProv.new('getIdentities', testAccount, 'zimbraPrefIdentityId', 'zimbraPrefIdentityName')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('name testID1') && data[1].include?('name testID2')
  end,
  v(ZMProv.new('gid', testAccount, 'zimbraPrefIdentityName')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('testID2') && data[1].include?('zimbraPrefIdentityName')
  end,
  v(ZMProv.new('modifyIdentity', testAccount, 'testID1', 'zimbraPrefIdentityName', 'testID11')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  v(ZMProv.new('mid', testAccount, 'testID2', 'zimbraPrefIdentityName', 'testID22')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  v(ZMProv.new('getIdentities', testAccount)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('testID11') && data[1].include?('testID22')
  end,
  v(ZMProv.new('gid', testAccount)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('testID11') && data[1].include?('testID22')
  end,
  v(ZMProv.new('deleteIdentity', testAccount, 'testID11')) do |mcaller, data|
    mcaller.pass = data[0]
  end,
  v(ZMProv.new('did', testAccount, 'testID22')) do |mcaller, data|
    mcaller.pass = data[0]
  end,
  v(ZMailAdmin.new('-m', testAccount, 'gaf')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  v(RunCommandOnMailbox.new(File.join(Command::ZIMBRAPATH,'bin','mysql'),Command::ZIMBRAUSER,'-e', 
                             "\"select * from zimbra.mailbox where comment like \\\"#{testAccount.name}\\\";\"")) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].empty?
  end,
  #Delete Account
  v(ZMProv.new('da', testAccount.name)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  v(RunCommandOnMailbox.new(File.join(Command::ZIMBRAPATH,'bin','mysql'),Command::ZIMBRAUSER,'-e', 
                             "\"select * from zimbra.mailbox where comment like \\\"#{testAccount.name}\\\";\"")) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].empty?
  end,
  v(RunCommandOnMailbox.new(File.join(Command::ZIMBRAPATH,'bin','mysql'),Command::ZIMBRAUSER,'-e', 
                             "\"select * from zimbra.mailbox where comment like \\\"#{testAccountTwo.name}\\\";\"")) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].empty?
  end,
  v(ZMProv.new('DeleteAccount', testAccountTwo.name)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  v(RunCommandOnMailbox.new(File.join(Command::ZIMBRAPATH,'bin','mysql'),Command::ZIMBRAUSER,'-e', 
                             "\"select * from zimbra.mailbox where comment like \\\"#{testAccountTwo.name}\\\";\"")) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].empty?
  end,
  v(cb("zmprov syg check") do
    response = []
    ZMProv.new('ca', testAccountFour.name, testAccountFour.password).run
    ZMProv.new('ma', testAccountFour.name, 'description','ting').run
    syg1 = ZMProv.new('syg', Model::TARGETHOST,'|', 'grep', 'token').run
    resultbefore = syg1[1][/token\s=\s([^,]*).*/, 1]
    ZMProv.new('ma', testAccountFour.name, 'description', 'tong').run
    syg2 = ZMProv.new('syg', Model::DOMAIN.to_s,'|', 'grep', 'token').run
    resultafter = syg2[1][/token\s=\s([^,]*).*/, 1]
    if resultbefore.eql? resultafter
      response = ["Script Failure : syg token is same"]
      exitCode = 1
    else
      response = ["Success"]
      exitCode = 0
    end
    [exitCode, response]
  end) do |mcaller,data|
    mcaller.pass = data[0] == 0
    if(not mcaller.pass)
      class << mcaller
      attr :badones, true
    end
      mcaller.badones = data[1]
    end
  end,
  v(ZMProv.new('ca', testAccountFive.name, testAccountFive.password)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  v(ZMProv.new('aaa', testAccountFive.name, 'alias'+testAccountFive.name)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  v(ZMProv.new('ga', testAccountFive.name)) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && (data[1].include?('zimbraMailAlias: alias'+testAccountFive.name)) && (data[1].include?("zimbraFeatureShortcutAliasesEnabled: TRUE"))
  end,
  v(ZMProv.new('raa', testAccountFive.name, 'alias'+testAccountFive.name)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  v(ZMProv.new('ga', testAccountFive.name)) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && !(data[1].include?('zimbraMailAlias: alias'+testAccountFive.name)) && (data[1].include?("zimbraFeatureShortcutAliasesEnabled: TRUE"))
  end,
 
  #Bug 96740
  
  v(ZMProv.new('ca', testAccountSix.name, testAccountSix.password)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  
  v(ZMProv.new('ca', testAccountSeven.name, testAccountSeven.password)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
    
  v(ZMProv.new('aaa', testAccountSix.name, 'alias'+testAccountSix.name)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end, 
  
  v(ZMProv.new('ga',testAccountSix.name, 'mail')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?(testAccountSix.name) && data[1].include?('alias'+testAccountSix.name)
  end,
  
  v(ZMProv.new('cd','testdomain.what.com')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  
  v(ZMProv.new('ra', testAccountSix.name,'newuser@testdomain.what.com' )) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  
  v(ZMProv.new('ca', testAccountSix.name, testAccountSix.password)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  
  v(ZMProv.new('aaa', testAccountSix.name, 'alias'+testAccountSix.name)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end, 
  
  v(ZMProv.new('ra', testAccountSix.name, testAccountSeven.name)) do |mcaller, data|
    mcaller.pass = data[0] != 0 && data[1].include?('ERROR: account.ACCOUNT_EXISTS (email address already exists: '+testAccountSeven.name+')')
  end,  
  
  v(ZMProv.new('ra', testAccountSix.name,'uniquenewuser@testdomain.what.com' )) do |mcaller, data|
    mcaller.pass = data[0] != 0 && data[1].include?('ERROR: account.ALIAS_EXISTS (email address alias already exists: [alias'+testAccountSix.name.split("@")[0]+'@testdomain.what.com])')
  end,
  
  v(ZMProv.new('DeleteAccount', 'newuser@testdomain.what.com')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  
  v(ZMProv.new('DeleteAccount', testAccountSix.name)) do |mcaller, data|
   mcaller.pass = data[0] == 0
  end,
   
  v(ZMProv.new('DeleteAccount', testAccountSeven.name)) do |mcaller, data|
   mcaller.pass = data[0] == 0
  end,
   
  v(ZMProv.new('dd','testdomain.what.com')) do |mcaller, data|
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
  Engine::Simple.new(Model::TestCase.instance).run
end