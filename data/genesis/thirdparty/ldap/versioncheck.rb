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
require "action/zmlocalconfig"
require "#{mypath}/install/configparser"
require 'action/oslicense'

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Ldap version test"

include Action 


(mCfg = ConfigParser.new).run

#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [       
  mCfg.getServersRunning('ldap').map do |x|
    v(RunCommand.new(File.join(Command::ZIMBRAPATH,'libexec','zmslapd'),
                     Command::ZIMBRAUSER,'-V', '2>&1', Model::Host.new(x))) do |mcaller, data|
      #result = data[1].select {|w| w =~ /@\(#\)\s+\$OpenLDAP:\s+slapd/}[0][/slapd\s+\d+\.\d+(\.\S+)?/].split(/ /)[-1]
      result = data[1][/(\d+\.\d+\S+)/]
      #result = data[1]
      mcaller.pass = data[0] == 1 && result == OSL::LegalApproved['openldap'] #expected
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {x + ' - open ldap version' => {"IS"=>result, "SB"=>OSL::LegalApproved['openldap']}}
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
