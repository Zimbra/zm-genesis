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
 
require "model" 
require "action/block"
require "action/runcommand" 
require "action/verify"
#require "action/zmcontrol" 

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Ldap monitor test"

include Action 

ldapUrls = []
monitorAcls = [['cn=config', 'ldap_root_password'], ['uid=zimbra,cn=admins,cn=zimbra', 'zimbra_ldap_password']]
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
    ldapUrls = ldapUrl.chomp.split(/\n/)
    mcaller.pass = data[0] == 0 && ldapUrls != [] 
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'ldap_url' => {"IS"=>ldapUrl, "SB"=>"Defined"}}
    end
  end,
  
  v(cb("back-monitor") do
    exitCode = 0
    result = []
    ###### get ldap passwords from ldap server
    monitorAcls.each do |acl|
      ldapUrls.each do |url|
        mObject = RunCommandOn.new(url[/ldaps?:\/\/([^:]+)/, 1],
                                   File.join(Command::ZIMBRAPATH, 'bin', 'zmlocalconfig'), 'root',
                                   '-s', '-m  nokey', acl[1])
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
                                 '-D', acl[0],
                                 '-b cn=Current,cn=Time,cn=Monitor +')
        mResult = mObject.run
        exitCode = mResult[0] if mResult[0] != 0
        iResult = mResult[1]
        if(iResult =~ /Data\s+:/)
          iResult = iResult[/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
        end
        result << [acl, url, iResult[/monitorTimestamp.*$/]]
      end
    end
    [exitCode, result]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].select { |w| w[2] == nil}.empty?
      if (not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {'ldap monitor check' => {}}
        data[1].select { |w| w[2] == nil}.each do |res|
          crt = {res[1] => {"IS"=>"#{res[2]}", "SB"=>'UTC time'}}
          mcaller.badones['ldap monitor check'][res[0]] = crt
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