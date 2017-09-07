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
require "action/zmlocalconfig"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Ldap mime types test"

include Action 

mimeTypes = {'text/plain' => {'zimbraMimeHandlerClass' => 'com.zimbra.cs.mime.handler.TextPlainHandler',
                              'objectClass' => 'zimbraMimeEntry'},
             'text/enriched' => {'zimbraMimeHandlerClass' => 'com.zimbra.cs.mime.handler.TextEnrichedHandler',
                                 'objectClass' => 'zimbraMimeEntry'},
             'all' => {'zimbraMimeHandlerClass' => 'ConverterHandler',
                       'objectClass' => 'zimbraMimeEntry'}}
mimeTypes.default = 'Missing'

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
  
  v(ZMLocalconfig.new('-s', '-m', 'nokey', 'zimbra_ldap_password')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && (ldapPassword = data[1].chomp) !~ /Warning: null valued key/
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'zimbra_ldap_password' => {"IS"=>ldapPassword, "SB"=>"Defined"}}
    end
  end,

  ZMLocalconfig.new('-m', 'nokey', 'ldap_url').run[1].chomp.split.map do |x|
    v(cb("mime types") do
      exitCode = 0
      result = {}
      mimeTypes.keys.each do |mtype|
        mObject = RunCommand.new(File.join(Command::ZIMBRAPATH, 'common', 'bin', 'ldapsearch'), Command::ZIMBRAUSER,
                                 '-LLL',
                                 '-H', x,
                                 '-x', '-w', ldapPassword,
                                 '-D', 'uid=zimbra,cn=admins,cn=zimbra',
                                 '-b', 'cn=mime,cn=config,cn=zimbra',
                                 'cn=' + mtype)
        mResult = mObject.run
        if mResult[0] != 0
          exitCode = mResult[0] 
          next
        end
        #iResult = mResult[1]
        iResult = Hash[*mResult[1].split(/\n/).select {|w| w =~ /\S+:\s+\S+/}.collect {|w| w.split(/:\s+/)}.flatten]
        iResult.reject! {|k,v| !mimeTypes[mtype].has_key?(k)}
        iResult.default = 'Missing'
        result[mtype] = iResult
      end
      [exitCode, result]
    end) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1] == mimeTypes
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
