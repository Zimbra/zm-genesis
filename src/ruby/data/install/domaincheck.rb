#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2007 Zimbra
#
#

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
mypath = 'data'
if($0 =~ /data\/genesis/)
  mypath += '/genesis'
end

require "model" 
require "action/block"
require "action/runcommand" 
require "action/verify"
require "#{mypath}/install/configparser"
require "#{mypath}/install/utils"
require "#{mypath}/install/attributeparser"
require "action/buildparser"
include REXML 

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "domain test"

include Action 

existing = {}
expected = {}

exceptions = {
              'description' => Utils::Test.new('some text') {|sb, is| true},
              'zimbraACE' => Utils::Test.new('Zimbra access control list or missing') {|sb, is| true},
              'zimbraCreateTimestamp' => Utils::Test.new('timestamp') do |sb, is|
                                           is[0] =~ /\d+Z/
                                         end,
              'zimbraDomainName' => Utils::Test.new(Utils::zimbraDefaultDomain()) do |sb, is|
                                      is[0] == Utils::zimbraDefaultDomain()
                                    end,
              'zimbraDomainStatus' => Utils::Test.new(Utils::zimbraDefaultDomain()) do |sb, is|
                                        is[0] == 'active'
                                      end,
              'zimbraDomainType' => Utils::Test.new(Utils::zimbraDefaultDomain()) do |sb, is|
                                        is[0] == 'local'
                                      end,
              'zimbraGalAccountId' => Utils::Test.new('galsync acount id') do |sb, is|
                                        if Utils::isUpgradeFrom('((6|7)\.\d+\.\d+|8\.0\.0_BETA[1-4])')
                                          is[0] =~ /Missing/
                                        else
                                          ZMProv.new('gds', is[0], 'zimbraDataSourceName').run[1] =~ /zimbraDataSourceName:\s+InternalGAL/
                                        end
                                      end,
              'zimbraId' => Utils::Test.new("id") {|sb, is| is[0] !~ /Missing/},
              'zimbraPasswordChangeListener' => Utils::Test.new('syncListener or missing') do |sb, is|
                                                  is[0] =~ /(Missing|syncListener)/
                                                end,
              'zimbraPreAuthKey' => Utils::Test.new('auth key or missing') {|sb, is| is[0] =~ /(Missing|[\da-f]{64})/},
              #bug 32295: set zimbraSkinLogoURL to http://www.zimbra.com on FOSS, do not set it on NET
              'zimbraSkinLogoURL' => Utils::Test.new('http://www.zimbra.com on FOSS, unset on NETWORK') do |sb, is|
                                       if BuildParser.instance.targetBuildId =~ /_FOSS/i
                                         is[0] =~ /http:\/\/www\.zimbra\.com\b/
                                       else
                                         is[0] =~ /Missing/
                                       end
                                     end,
             }
exceptions.default = Utils::Test.new("default = Missing") {|sb, is| is[0] =~ /Missing/}

#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [       
  v(cb("domain attributes check") do
    mObject = AttributeParser.new('domain')
    mObject.run()
    expected = mObject.attributes
    exitCode = 0
    result = {}
    mObject = RunCommand.new(File.join(Command::ZIMBRAPATH, 'bin','zmprov'), Command::ZIMBRAUSER,
                             'gd', Utils::zimbraDefaultDomain())
    data = mObject.run
    iResult = data[1]
    if(iResult =~ /Data\s+:/)
      iResult = iResult[/Data\s+:\s+([^\s}].*?)$\s+\}/m, 1]
    end
    if data[0] != 0
      [data[0], iResult]
    else
      existing = {}
      toks = nil
      iResult.split(/\n/).each do |line|
        next if line =~ /^#/
        if line =~ /^\S+:\s+.*/
          if toks != nil
            existing[toks[0]] = [] if !existing.has_key? toks[0]
            existing[toks[0]] << toks[1].chomp
          end
          toks = line.split(/:\s+/, 2)
        else
          toks[1] += line
        end
      end
      existing[toks[0]] = [] if !existing.has_key? toks[0]
      existing[toks[0]] << toks[1].chomp
      existing.default = ['Missing']
      iResult = {}
      expected.each_key do |key|
        iResult[key] = existing[key]
      end
      [exitCode, iResult]
    end
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 &&
                   data[1].keys().select  do |w|
                     data[1][w].sort != expected[w]['default'].sort
                   end.select do |w| 
                     !(exceptions[w].call(expected[w]['default'], data[1][w]))
                   end.empty?
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'default domain test' => {}}
      if data[0] != 0
        mcaller.badones['default domain test'] = {'Exit code' => {"IS" => "#{data[0]} - #{data[1]}", "SB" => '0 - Success'}}
      else
        expectedKeys = expected.keys
        realityKeys = data[1].keys
        unexpectedKeys = realityKeys - expectedKeys
        commonKeys = realityKeys - unexpectedKeys
        missingKeys = expectedKeys - realityKeys
        mResult = {}
        realityKeys.select do |w|
  
          (data[1][w] & expected[w]['default']).size != expected[w]['default'].size
        end.select do |w|
          data[1][w] != expected[w]['default']
        end.select do |w|
          !(exceptions[w].call(expected[w]['default'], data[1][w]))
        end.each do |w|
          mResult[w] = {"IS" => data[1][w].join(","),
                        "SB" => if exceptions.has_key?(w)
                                  exceptions[w].to_str
                                else
                                  expected[w]['default'].join(",")
                                end}
        end
        missingKeys.select do |w|
          expected[w]['default'] != ["Skip - no default"]
        end.each {|w| mResult[w] = {"IS" => "missing", "SB" => expected[w]['default'].join(",")}}
        mcaller.badones['default domain test'] = mResult
      end
    end
  end,
        
  v(cb("GAL attributes check") do
    result = {}
    mObject = RunCommand.new(File.join(Command::ZIMBRAPATH, 'bin','zmprov'), Command::ZIMBRAUSER,
                             'gd', Utils::zimbraDefaultDomain(), 'zimbraGalLdapAttrMap')
    data = mObject.run
    iResult = data[1]
    if(iResult =~ /Data\s+:/)
      iResult = iResult[/Data\s+:\s+([^\s}].*?)$\s+\}/m, 1]
    end
    if data[0] != 0
      [data[0], iResult]
    else
      existing = []
      toks = nil
      iResult.split(/\n/).each do |line|
        next if line =~ /^(#|\s*$)/
        if line =~ /^\S+:\s+.*/
          existing << toks[1].chomp if toks != nil
          toks = line.split(/:\s+/, 2)
        else
          toks[1] += line
        end
      end
      existing << toks[1].chomp
      [data[0], existing]
    end
  end) do |mcaller, data|
    expected = ['co=workCountry',
                'company=company',
                'description=notes',
                #'displayName,cn=fullName,fullName2,fullName3,fullName4,fullName5,fullName6,fullName7,fullName8,fullName9,fullName10',
                'facsimileTelephoneNumber,fax=workFax',
                'givenName,gn=firstName',
                'homeTelephoneNumber,homePhone=homePhone',
                'initials=initials',
                'l=workCity',
                'mobileTelephoneNumber,mobile=mobilePhone',
                'msExchResourceSearchProperties=zimbraAccountCalendarUserType',
                'objectClass=objectClass',
                'ou=department',
                'pagerTelephoneNumber,pager=pager',
                'physicalDeliveryOfficeName=office',
                'postalCode=workPostalCode',
                'sn=lastName',
                'st=workState',
                'street,streetAddress=workStreet',
                'telephoneNumber=workPhone',
                'title=jobTitle',
                'zimbraCalResBuilding=zimbraCalResBuilding',
                'zimbraCalResCapacity,msExchResourceCapacity=zimbraCalResCapacity',
                'zimbraCalResContactEmail=zimbraCalResContactEmail',
                'zimbraCalResFloor=zimbraCalResFloor',
                'zimbraCalResLocationDisplayName=zimbraCalResLocationDisplayName',
                'zimbraCalResSite=zimbraCalResSite',
                'zimbraCalResType,msExchResourceSearchProperties=zimbraCalResType',
                'zimbraDistributionListSubscriptionPolicy=zimbraDistributionListSubscriptionPolicy',
                'zimbraDistributionListUnsubscriptionPolicy=zimbraDistributionListUnsubscriptionPolicy',
                'whenChanged,modifyTimeStamp=modifyTimeStamp',
                'whenCreated,createTimeStamp=createTimeStamp',
                'zimbraId=zimbraId',
                'zimbraMailDeliveryAddress,zimbraMailAlias,mail=email,email2,email3,email4,email5,email6,email7,email8,email9,email10,email11,email12,email13,email14,email15,email16',
                'zimbraMailForwardingAddress=member',
                'zimbraPhoneticCompany,ms-DS-Phonetic-Company-Name=phoneticCompany',
                'zimbraPhoneticFirstName,ms-DS-Phonetic-First-Name=phoneticFirstName',
                'zimbraPhoneticLastName,ms-DS-Phonetic-Last-Name=phoneticLastName',
                '(binary) userSMIMECertificate=userSMIMECertificate',
                '(certificate) userCertificate=userCertificate'
                ]
    expected.push(Utils::applianceVersion =~ /6\.0\.7\./ ? 'displayName,cn=fullName' : 'displayName,cn=fullName,fullName2,fullName3,fullName4,fullName5,fullName6,fullName7,fullName8,fullName9,fullName10')
    mcaller.pass = data[0] == 0 && data[1].sort == expected.sort
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'gal attr map test' => {}}
      if data[0] != 0
        mcaller.badones['gal attr map test'] = {'Exit code' => {"IS" => "#{data[0]} - #{data[1]}", "SB" => '0 - Success'}}
      else
        reality = data[1]
        unexpected = reality - expected
        missing = expected - reality
        mResult = {}
        missing.each {|w| mResult[w] = {"IS" => 'Missing', "SB" => w}}
        unexpected.each {|w| mResult[w] = {"IS" => w, "SB" => 'Missing'}}
        mcaller.badones['gal attr map test'] = mResult
      end
    end
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