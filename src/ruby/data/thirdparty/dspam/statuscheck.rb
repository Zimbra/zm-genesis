#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2011 VMware Zimbra
#
# Test case for Bug 12185 - disable dspam by default
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

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Dspam enabled check"

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
  
  mCfg.getServersRunning('mta').map do |x|
  [
  v(cb("dspam status") do
    server = RunCommandOn.new(x, File.join(Command::ZIMBRAPATH,'bin', 'zmlocalconfig'), Command::ZIMBRAUSER,
                              '-m', 'nokey', 'amavis_dspam_enabled').run[1].chomp
    dspamEnabled = dspamEnabled == 'TRUE' ? true : false
    mResult = RunCommandOn.new(x, 'cat', 'root', File.join(Command::ZIMBRAPATH,'conf', 'amavisd.conf')).run
    mResult.push(dspamEnabled)
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].split(/\n/).select {|w| w =~ /^(\s*[^#].*)?\$dspam/}.empty? ^ data[3]
  end,
  ]
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
