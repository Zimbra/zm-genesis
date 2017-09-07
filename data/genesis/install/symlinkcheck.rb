#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2006 Zimbra
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
require "#{mypath}/install/utils"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Zimbra symlinks check"


include Action
include Model


#
# Setup
#
current.setup = [
  
]
   
#
# Execution
#
current.action = [  
  v(cb("Dangling symlinks check") do
    mResult = RunCommand.new('find', 'root', Command::ZIMBRAPATH, '-follow', '-maxdepth 2', '-type l').run
  end) do |mcaller, data|
    mres = data[1].split(/\n/)
    mres = mres.select {|w| w !~ /#{Regexp.compile(File.join(Command::ZIMBRAPATH, 'libmemcached'))}/} if Utils.isUpgradeFrom('(7\.\d+|8\.0)\.\d+')
    mcaller.pass = data[0] == 0 && mres.empty? #data[1].split(/\n/).select {|w| w =~ /#{Regexp.compile(Command::ZIMBRAPATH)}/}.empty?
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      if(data[1] =~ /Data\s+:/)
        data[1] = (data[1])[/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
      end
      mcaller.badones = {'dangling symlinks' => {"SB" => 'not found',
                                                 "IS" => mres.collect {|w| w.sub(/[^:]+:\s*/, '')}}}
    end
  end,
  
  v(cb("0-byte file symlinks check") do
    mResult = RunCommand.new('find', 'root', Command::ZIMBRAPATH,
                             '-type', 'f',
                             '-size', '0c').run
    if(mResult[1] =~ /Data\s+:/)
      mResult[1] = mResult[1][/Data\s+:\s+([^\s}].*?)$\s+\}/m, 1]
    end
    emptyFiles = mResult[1].split(/\n/).collect{|w| File.basename(w)}
    mResult = RunCommand.new('find', 'root', Command::ZIMBRAPATH,
                             '-type', 'l', '-ls').run
    if(mResult[1] =~ /Data\s+:/)
      mResult[1] = mResult[1][/Data\s+:\s+([^\s}].*?)$\s+\}/m, 1]
    end
    bogusLinks = mResult[1].split(/\n/).select {|w| emptyFiles.include?File.basename(w[/-> (.*)/, 1])}
    [mResult[0], bogusLinks]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].empty?
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      messages = {}
      data[1].each do |err|
        messages.merge!({err[/([^\s]+)\s+->/, 1] => {"SB" => 'not found',
                                                     "IS" => err[/(->\s+[^\s]+)/, 1]}})
      end
      mcaller.badones = {'bogus symlinks' => messages}
    end
  end,
  
  #while here check for multiple 3rd party packages
  v(cb("3rd party duplicates check") do
    exitCode = 0
    duplicates = {}
    exclude = [File.join(Command::ZIMBRAPATH,'jetty'),
               File.join(Command::ZIMBRAPATH,'postfix'),
               File.join(Command::ZIMBRAPATH,'net-snmp'),
              ]
    exclude.push(File.join(Command::ZIMBRAPATH,'cyrus-sasl')) if Utils::isUpgrade() && Utils.isUpgradeFrom('(6|7).\d.\d+')
    mResult = RunCommand.new('find', 'root', Command::ZIMBRAPATH,
                             '-maxdepth', '1', '-type', 'l', '-ls').run
    if(mResult[1] =~ /Data\s+:/)
      mResult[1] = mResult[1][/Data\s+:\s+([^\s}].*?)$\s+\}/m, 1]
    end
    #symLinks = mResult[1].split(/\n/)
    symLinks = Hash[*mResult[1].split(/\n/).collect {|w| w[/(\S+\s+->\s+\S+)/, 1]}.collect{|w| w.split(/\s+->\s+/)}.flatten]
    mResult = RunCommand.new('find', 'root', Command::ZIMBRAPATH,
                             '-maxdepth', '1', '! -type l', '-print').run #'-name', "\"*\"", '-print').run
    if(mResult[1] =~ /Data\s+:/)
      mResult[1] = mResult[1][/Data\s+:\s+([^\s}].*?)$\s+\}/m, 1]
    end
    all = mResult[1].split(/\n/).sort
    symLinks.delete_if {|k, v| exclude.include? k}.each_pair do |k, v|
      crt = all.select {|w| w =~ /#{Regexp.new(k)}/}.select {|w| w !~ /#{Regexp.new(v)}/}
      crt = crt.delete_if{|w| w =~ /nginx-0\.9-/} #bug #73726
      crt = crt.delete_if{|w| w =~ /openldap-2\.4\.3[89]/}
      if !crt.empty?
        duplicates[k] = {"SB" => v, "IS" => "old version - " + crt.join(' ')} 
        exitCode += 1
      end
    end
    [exitCode, duplicates]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].empty?
  end,
  
  if RunCommand.new('mount', 'root').run[1].split(/\n/).select {|w| w =~/on\s+#{Command::ZIMBRAPATH}\s+/}.size == 1
  [
    v(RunCommand.new('ls', 'root', '/opt/zimbra')) do |mcaller, data|
      mcaller.pass = data[0] == 0 && !data[1].split(/\n/).select {|w| w =~ /lost\+found/}.empty?
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