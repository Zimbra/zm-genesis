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
current.description = "Ldap mime types test"

include Action 

expected = {'zimbraMimeType' => 'text/plain',
            'cn' => 'text/plain',
            'objectClass' => 'zimbraMimeEntry',
            'zimbraMimeIndexingEnabled' => 'TRUE',
            'zimbraMimeHandlerClass' => 'TextPlainHandler',
            'zimbraMimeFileExtension' => 'txt',
#            'zimbraMimeFileExtension' => 'text',
            'description' => 'Plain Text Document'
           }
mimeTypes = ['cn=text/plain']
ldapUrls = []
ldapPassword = 'UNDEF'

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
    ldapUrls = ldapUrl.chomp.split()
    mcaller.pass = data[0] == 0 && ldapUrls != [] 
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'ldap_url' => {"IS"=>ldapUrl, "SB"=>"Defined"}}
    end
  end,
  
  v(RunCommand.new(File.join(Command::ZIMBRAPATH,'bin','zmlocalconfig'), Command::ZIMBRAUSER,
                              '-s', '-m nokey', 'zimbra_ldap_password')) do |mcaller, data|
    data[0] = 1 if data[1] =~ /Warning: null valued key/
    ldapPassword = data[1]
    if(ldapPassword =~ /Data\s+:/)
      ldapPassword = ldapPassword[/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
    end
    ldapPassword.chomp!
    mcaller.pass = data[0] == 0 && ldapPassword != 'UNDEF' 
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'zimbra_ldap_password' => {"IS"=>ldapPassword, "SB"=>"Defined"}}
    end
  end,

  v(cb("mime types") do
    exitCode = 0
    result = []
    mimeTypes.each do |mtype|
      ldapUrls.each do |url|
        mObject = RunCommand.new(File.join(Command::ZIMBRAPATH, 'bin', 'ldapsearch'), Command::ZIMBRAUSER,
                                 '-LLL',
                                 '-H', url,
                                 '-x', '-w', ldapPassword,
                                 '-D', 'uid=zimbra,cn=admins,cn=zimbra',
                                 '-b', 'cn=mime,cn=config,cn=zimbra',
                                 mtype)
        mResult = mObject.run
        exitCode = mResult[0] if mResult[0] != 0
        iResult = mResult[1]
        if(iResult =~ /Data\s+:/)
          iResult = iResult[/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
        end
        iResult = Hash[*iResult.split(/\n/).collect {|w| w.chomp.split(/\s*:\s*/).collect {|y| y.strip()}}.flatten]
        result = expected.keys.select {|w| !iResult.has_key?(w) || expected[w] != iResult[w]}.collect {|w| [w,[expected[w], iResult[w]]]}
      end
    end
    [exitCode, result]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].empty?
      if (not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {'mime types check' => {}}
        data[1].each do |res|
          mcaller.badones['mime types check'][res[0]] = {"IS" => res[1][1] == nil ? 'Missing' : res[1][1], "SB" => res[1][0]}
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
