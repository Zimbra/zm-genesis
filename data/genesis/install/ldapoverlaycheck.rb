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
#

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 

mypath = 'data'
if($0 =~ /data\/genesis/)
  mypath += '/genesis'
end

require "model"
!require 'model/user'
require "action/block"
require "action/runcommand"
require "action/zmprov"
require "action/verify"
require "#{mypath}/upgrade/pre/provision"
require "#{mypath}/install/configparser"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Ldap overlay test"

include Action 

ldapUrls = []
overlays = [['cn=config', 'ldap_root_password']]
name = File.basename(__FILE__,'.rb')+Time.now.to_i.to_s 

testAccountOne = Model::User.new("#{name+'1'}@#{Provision::DefaultDomain}", Model::DEFAULTPASSWORD)
testAccountTwo = Model::User.new("#{name+'2'}@#{Provision::DefaultDomain}", Model::DEFAULTPASSWORD)
(mCfg = ConfigParser.new).run
mStores = mCfg.getServersRunning('store')
#
# Setup
#
current.setup = [
   
] 
#
# Execution
#



current.action = [       
  v(RunCommand.new(File.join(Command::ZIMBRAPATH,'bin','zmlocalconfig'), Command::ZIMBRAUSER,
                              '-s', '-m nokey', 'ldap_url')) do |mcaller, data|
    data[0] = 1 if data[1] =~ /Warning: null valued key/
    ldapUrl = data[1]
    if(ldapUrl =~ /Data\s+:/)
      ldapUrl = ldapUrl[/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
    end
    ldapUrls = ldapUrl.strip.split(/\s+/)
    mcaller.pass = data[0] == 0 && ldapUrls != [] 
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'ldap_url' => {"IS"=>ldapUrl, "SB"=>"Defined"}}
    end
  end,
  
  ZMProv.new('flushCache', 'license', store = Model::Host.new(mStores.first)),
  ZMProv.new('cddl',testAccountOne, store),
  ZMProv.new('CreateAccount', testAccountTwo.name, testAccountTwo.password, store),
  ZMProv.new('adlm', testAccountOne, testAccountTwo, store),
  
  v(cb("dynamic list overlay") do
    exitCode = 0
    result = []
    domain = ZMProv.new('gcf', 'zimbraDefaultDomainName').run[1][/zimbraDefaultDomainName:\s+(\S+)/, 1]
    mBase = "dc=" + domain.gsub(/\./, ",dc=")
    ###### get ldap passwords from ldap server
    overlays.each do |ovl|
      ldapUrls.each do |url|
        mObject = RunCommandOn.new(url[/ldaps?:\/\/([^:]+)/, 1],
                                   File.join(Command::ZIMBRAPATH, 'bin', 'zmlocalconfig'), 'root',
                                   '-s', '-m  nokey', ovl[1])
        mResult = mObject.run
        if(mResult[1] =~ /Data\s+:/)
          mResult[1] = mResult[1][/Data\s+:\s+([^\s}].*?)$\s*\}/m, 1]
        end
        pwd = mResult[1].chomp
        mObject = RunCommand.new(File.join(Command::ZIMBRAPATH, 'common', 'bin', 'ldapsearch'), Command::ZIMBRAUSER,
                                 '-LLL',
                                 '-H', url,
                                 '-x', '-w',
                                 pwd,
                                 '-D', ovl[0],
                                 '-b', mBase,
                                 "cn=#{name}1")
        mResult = mObject.run
        exitCode = mResult[0] if mResult[0] != 0
        iResult = mResult[1]
        if(iResult =~ /Data\s+:/)
          iResult = iResult[/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
        end
        result << [ovl, url, iResult]
      end
    end
    [exitCode, result]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].select { |w| w[2] !~ /member: uid=#{name}2/}.empty?
      if (not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {'ldap overlay check' => {}}
        data[1].each do |res|
          crt = {res[1] => {"IS"=>"#{res[2]}", "SB"=>"member: uid=#{name}2"}}
          mcaller.badones['ldap overlay check'][res[0].first] = crt
        end
    end
  end,
  
]
    	

#
# Tear Down
#
current.teardown = [
  ZMProv.new('da', testAccountTwo.name),
  ZMProv.new('ddl', testAccountOne.name)
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end 