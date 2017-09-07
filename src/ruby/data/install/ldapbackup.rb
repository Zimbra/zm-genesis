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
# Backup ldap (zmslapcat) as the last step - /tmp/ldap.bak.<BUILD_ID>.<install|upgrade>

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
require "#{mypath}/install/historyparser"
require "action/zmlocalconfig"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Ldap backup"

include Action 

mParser = HistoryParser.new
mParser.run

#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [       

  v(cb("ldap backup") do
    master = ZMLocal.new('ldap_master_url').run[/\/\/([^:\.]+)/, 1]
    host = Model::Host.new(master, Model::TARGETHOST.domain)
    mResult = RunCommand.new('rm', 'root', '-rf', bak = File.join('/tmp', 'ldap.bak'), host).run
    next mResult if mResult[0] != 0
    id = mParser.id + "." + (mParser.isUpgrade ? 'upgrade' : 'install')
    mResult = RunCommand.new('libexec/zmslapcat', Command::ZIMBRAUSER, '/tmp', '2>&1', host).run
    next(mResult) if mResult[0] != 0 || !mResult[1].empty?
    mResult = RunCommand.new('mv', Command::ZIMBRAUSER, '-f', '/tmp/ldap.bak', '/tmp/ldap.bak.' + id, host).run
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'ldap backup' => {"SB" =>"Success", "IS" => data[1]}}
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