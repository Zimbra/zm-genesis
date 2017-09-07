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
# checks that there are no leading spaces on include lines

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
require "action/buildparser" 
require "action/zmlocalconfig"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "slapd conf test"

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
  
  v(cb("slapd conf check") do
    res = [] 
    ['slapd.conf.default', 'slapd.conf'].each do |fileName|
      master = ZMLocal.new('ldap_master_url').run[/\/\/([^:\.]+)/, 1]
      host = Model::Host.new(master, Model::TARGETHOST.domain)
      mObject = RunCommandOn.new(host, "cat", 'root', File.join(Command::ZIMBRAPATH,'/common/etc/openldap/', fileName))
      mResult = mObject.run
      iResult = mResult[1]
      if(iResult =~ /Data\s+:/)
        iResult = (iResult)[/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
      end
      if mResult[0] == 0
        iResult = iResult.split(/\n/).select {|w| w =~ /^\s+include\s+\".*/}
      end
      res << [fileName, mResult[0], iResult]
      #[mResult[0], iResult]
    end
    [0, res]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].select {|w| !w[2].empty?}.empty?
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'slapd conf test' => {}}
      data[1].each do |err|
        mcaller.badones['slapd conf test'][File.join(Command::ZIMBRAPATH,'conf', err[0])] = {}
        if err[1] == 0
          mcaller.badones['slapd conf test'][File.join(Command::ZIMBRAPATH,'conf', err[0])] = {"IS"=>err[2].collect {|w| w}, "SB"=>err[2].collect {|w| w.strip()}}
        else
          mcaller.badones['slapd conf test'][File.join(Command::ZIMBRAPATH,'conf', err[0])] = {"IS"=>"Not found, exit code=#{err[1]}", "SB"=>"Found"}
        end
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