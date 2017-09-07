#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2007 Zimbra
# Check for errors in zimbra /tmp/install.out and /tmp/install.log:


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
require "action/zmcontrol"
require "#{mypath}/install/utils"
require "#{mypath}/install/configparser"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Default packages test"

include Action

(mCfg = ConfigParser.new()).run
networkPackages = ['zimbra-archiving', 'zimbra-convertd']
isNetwork = ZMControl.new('--version').run[1] !~ /FOSS/

#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [
  if !Utils.isUpgrade
    v(cb("default packages test") do
      mResult = RunCommand.new("/bin/ls", 'root', '-rt1', '/tmp/install.out.*').run
      next mResult if mResult[0] != 0
      mResult = RunCommand.new('grep', 'root', "\"Install zimbra-.*[[:space:]]\\[[yYnN]\\]\"", log = mResult[1].split(/\n/).last).run
      [mResult[0], Hash[*mResult[1].split(/\n/).collect {|w| w[/Install\s(zimbra.*)\]/, 1].split(/\s\[/)}.flatten], log]
    end) do |mcaller, data|
      expected = {'zimbra-proxy'     => 'y',
                  'zimbra-memcached' => 'y',
                 }
      mcaller.pass = data[0] == 0 && (error = expected.keys.select {|k| data[1][k] !~ /#{expected[k]}/i}).empty?
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {}
        error.each {|pkg| mcaller.badones["Install #{pkg}"] = {"IS" => data[1][pkg].nil? ? 'NOT FOUND' : data[1][pkg], "SB" => "#{expected[pkg].downcase} or #{expected[pkg].upcase}"}}
      end
    end
  end,
    
  if [59, 74].include?(Model::TARGETHOST.architecture)
  [
    if RunCommand.new('which', 'root', 'debsums').run[0] != 0
      v(RunCommand.new("apt-get", 'root', '-y', 'install', 'debsums'))  do |mcaller, data|
        mcaller.pass = data[0] == 0 
      end
    end,
  
    XPath.match(mCfg.doc, "//host[@name='#{Model::TARGETHOST}']/package/@name").collect{|w| w.value}.map do |x|
      v(RunCommand.new("debsums", 'root', x)) do |mcaller, data|
        errs = []
        mcaller.pass = if !networkPackages.include?(x) || isNetwork
                         data[1].split(/\n/).length > 0 &&
                         (errs = data[1].split(/\n/).select {|w| w !~ /(OK|FAILED)$/}).empty? &&
                         (errs += data[1].split(/\n/).select {|w| w =~ /FAILED$/}).empty? &&
                         data[1].split(/\n/).length == data[1].split(/\n/).select {|w| w =~ /OK$/}.length ||
                         data[1].split(/\n/).length == 1 && x == 'zimbra-logger'
                       else
                         data[0] != 0 && data[1] =~ /package #{x} is not installed/
                       end
        if(not mcaller.pass)
          class << mcaller
            attr :badones, true
          end
          mcaller.suppressDump("Suppress dump, the result has #{data[1].split(/\n/).size} lines") if data[1].split(/\n/).size >= 100
          mcaller.badones = {x + ' - md5sum test' => {"IS" => ((errs.empty? || errs.nil?) ? data[1].split(/\n/) : errs).slice(0, 10).push('...'), "SB" => "OK"}}
        end
      end
    end
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
