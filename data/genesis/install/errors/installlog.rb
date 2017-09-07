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
require "#{mypath}/install/utils"
require "#{mypath}/install/configparser"
require "#{mypath}/install/errorscanner"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Install errors detection test"

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
  if !Utils::isAppliance
  [
    mCfg.getServersRunning('.*').map do |x|
      v(cb("install.out errors detection test") do
        mResult = RunCommand.new("/bin/ls", 'root', '-rt1', '/tmp/install.out.*', h = Model::Host.new(x)).run
        next [mResult[0], {mResult[1] => '1'}, '/tmp/install.out.*'] if mResult[0] != 0
        mResult = RunCommand.new('/bin/cat', 'root', log = mResult[1].split(/\n/).last, h).run
        mResult[1] = if RUBY_VERSION =~ /1\.8\.\d+/
                       require 'iconv'
                       Iconv.new("US-ASCII//IGNORE", "UTF8").iconv(mResult[1])
                     else
                       mResult[1].encode('US-ASCII', 'UTF-8', {:invalid => :replace, :undef => :replace, :replace => '??'})
                     end
        next [mResult[0], {mResult[1] => '1'}, log] if mResult[0] != 0
        #sanitize it
        mResult[1] = mResult[1].split(/\n/)
        sel = /#{Regexp.compile(ErrorScanner::ERRORS.join('|'))}/
        rej = /#{Regexp.compile(ErrorScanner::EXCEPTS.join('|'))}/
        mResult[1] = mResult[1].select do |w|
                       w =~ sel
                     end.select do |w|
                       w !~ rej
                     end.collect do |w|
                       w.strip
                     end.uniq
        mResult << log
      end) do |mcaller, data|
        mcaller.pass = data[0] == 0 && data[1].empty?
        if(not mcaller.pass)
          class << mcaller
            attr :badones, true
          end
          mcaller.badones = {x + ' - ' + data.last + ' errors check' => {"IS"=>data[1].join("\n"), "SB"=>"No error"}}
        end
      end
    end
  ]
  end,
  
  if !Utils::isAppliance && Utils::upgradeHistory.last !~ /MACOSX/i
  [
    mCfg.getServersRunning('.*').map do |x|
      v(cb("install.log errors detection test") do
        (history = HistoryParser.new).run
        mResult = RunCommand.new("/bin/ls", 'root', '-rt1', '/tmp/install.log.*', h = Model::Host.new(x)).run
        next [mResult[0], {mResult[1] => '1'}, '/tmp/install.log.*'] if mResult[0] != 0
        log = mResult[1].split(/\n/).last
        mResult = RunCommand.new('/bin/cat', 'root', log, h).run
        next [mResult[0], {mResult[1] => '1'}, log] if mResult[0] != 0
        #sanitize
        #sles11 strips arch bits from the package name
        mId = history.id[/(.*)\.[^.+]/, 1]
        mResult[1] = mResult[1][/\n([^\n]*#{mId}.*)/m, 1].split(/\n/)
        sel = /#{Regexp.compile(ErrorScanner::ERRORS.join('|'))}/
        rej = /#{Regexp.compile(ErrorScanner::EXCEPTS.join('|'))}/
        mResult[1] = Hash[*mResult[1].select do |w|
                             w =~ sel
                           end.select do |w|
                             w !~ rej
                           end.collect {|w| ["\"#{w}\"", 1]}.flatten]
        mResult << log
      end) do |mcaller, data|
        mcaller.pass = data[0] == 0 && data[1].empty?
        if(not mcaller.pass)
          class << mcaller
            attr :badones, true
          end
          mcaller.badones = {data.last + ' errors check' => {}}
          data[1].keys.each_index do |i|
            mcaller.badones[x + ' - ' + data.last + ' errors check']["error #{i + 1}"] = {"IS"=>data[1].keys[i], "SB"=>"No error"}
          end
        end
      end
    end
  ]
  end,

  if Utils::isAppliance
  [
    v(cb("Appliance postinstall errors detection test") do
      res = []
      next [0, res] if !Utils::isAppliance
      if Utils::isAppliance
        errors << 'ERROR: account.NO_SUCH_ACCOUNT'
        errors << 'com.zimbra.common.service.ServiceException:\s+system failure'
      end
      mObject = Action::RunCommand.new('/bin/cat', 'root',
                                       File.join(File::SEPARATOR, 'opt', 'zcs-installer', 'log', 'appliance_postinstall.log'))
      data = mObject.run
      iResult = data[1]
      if(iResult =~ /Data\s+:/)
        iResult = (iResult)[/Data\s+:\s+([^\s}].*?)$\s*\}/m, 1]
      end
      if data[0] == 0
        #puts iResult.split(/\n/).select {|w| w =~ /#{Regexp.compile(errors.join('|'))}/}
        res = Hash[*iResult.gsub(/\n\t+/m, "\t").gsub(/\n(Caused by:\s+)/m, '\t\1').split(/\n/).select {|w| w =~ /#{Regexp.compile(errors.join('|'))}/}.select {|w| w !~ /#{Regexp.compile(excepts.join('|'))}/}.collect {|w| [w.chomp, 1]}.flatten]
      else
        res = [iResult]
      end
      [data[0], res]
    end) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1].empty?
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {'Appliance postinstall errors check' => {}}
        data[1].keys.each_index do |i|
          mcaller.badones['Appliance postinstall errors check']["error #{i + 1}"] = {"IS"=>data[1].keys[i], "SB"=>"No error"}
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
