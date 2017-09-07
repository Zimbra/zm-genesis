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
#require "action/buildparser" 
require "#{mypath}/install/historyparser"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "limits.conf test"

include Action 

skipMessage = "Feature not applicable on this OS"
expectedLimit = '524288'
history = HistoryParser.new
history.run
#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [       
  
  v(cb("limits.conf check") do 
    if history.platform =~ /MACOSX/i
      [0, skipMessage + "[#{history.platform}]"]
    else
      mObject = RunCommand.new("cat", 'root', "/etc/security/limits.conf")
      mResult = mObject.run
      iResult = mResult[1]
      if(iResult =~ /Data\s+:/)
        iResult = (iResult)[/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
      end
      if mResult[0] == 0
        iResult = iResult.split(/\n/).select {|w| w =~ /^zimbra\s+(hard|soft)\s+nofile\s+\d+.*/}
      end
      [mResult[0], iResult]
    end
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'/etc/security/limits.conf check' => {"IS"=>"#{data[1]}", "SB"=>"Exist"}}
    else
      if data[1] !~ /#{skipMessage}/
        hard = ['zimbra\s+hard\s+nofile\s' + expectedLimit,
                data[1].grep(/^zimbra\s+hard\s+nofile\s+#{expectedLimit}$/),
                data[1].grep(/^zimbra\s+hard\s+nofile\s+\d+$/)]
        soft = ['zimbra\s+soft\s+nofile\s' + expectedLimit,
                data[1].grep(/^zimbra\s+soft\s+nofile\s+#{expectedLimit}$/),
                data[1].grep(/^zimbra\s+soft\s+nofile\s+\d+$/)]
        mcaller.pass = hard[1].length == 1 && soft[1].length == 1
        if(not mcaller.pass)
          class << mcaller
            attr :badones, true
          end
          mcaller.badones = {'/etc/security/limits.conf check' => {'hard limit' => {"IS"=>"#{hard[2]}", "SB"=>"#{hard[0]}"},
                                                                   'soft limit' => {"IS"=>"#{soft[2]}", "SB"=>"#{soft[0]}"}}}
        end
      end
    end
  end,
  
  v(cb("pam limits check") do 
    if history.platform =~ /.*(UBUNTU|DEBIAN4.0).*/
      res = []
      exitCode = 0
      ['/etc/pam.d/su', '/etc/pam.d/common-session'].each do |file|
        mObject = RunCommand.new("cat", 'root', file)
        mResult = mObject.run
        exitCode += mResult[0]
        iResult = mResult[1]
        if(iResult =~ /Data\s+:/)
          iResult = (iResult)[/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
        end
        if mResult[0] == 0
          iResult = iResult.split(/\n/).select {|w| w =~ /^session\s+required\s+pam_limits\.so\s*/}
          if iResult.length != 1
            res << [file, iResult] 
            exitCode += 1
          end
        end
      end
      [exitCode, res]
    else
      [0, skipMessage + "[#{history.platform}]"]
    end
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 #&& !data[1].kind_of?(Array) 
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'pam limits check' => {}}
      data[1].each {|w| mcaller.badones['pam limits check'][w[0]] = {"IS"=>"#{w[1].length} entries: #{w[1].join('|')}", "SB"=>"1 entry:   session\\s+required\\s+pam_limits\.so"}}
    end
  end,
  
  v(cb("zimbra open files limit check") do 
    if(Model::TARGETHOST.architecture == 1 ||
       Model::TARGETHOST.architecture == 9) ||
       Model::TARGETHOST.architecture == 39
      [0, skipMessage + "[#{Model::TARGETHOST.architecture}]"]
    else
      mObject = RunCommand.new("ulimit", Command::ZIMBRAUSER, '-n')
      mResult = mObject.run
      iResult = mResult[1]
      if(iResult =~ /Data\s+:/)
        iResult = (iResult)[/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
      end
      [mResult[0], iResult.chomp]
    end
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && (data[1] == expectedLimit || data[1] =~ /#{skipMessage}/)
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'zimbra open files limit' => {"IS"=>data[1], "SB"=>expectedLimit}}
    end
  end,
  
  #limit maxproc 2048" >/etc/launchd.conf
  v(cb("launchd limits check") do 
    if(Model::TARGETHOST.architecture != 1 &&
       Model::TARGETHOST.architecture != 9 &&
       Model::TARGETHOST.architecture != 39)
      [0, {}]
    else
      expected = {'maxproc' => {'hard' => %r/2048\b|1000\b/,
                                'soft' => %r/2048\b|1000\b/
                               },
                 }
      mObject = RunCommand.new('launchctl', 'root', 'limit')
      mResult = mObject.run
      iResult = mResult[1]
      if(iResult =~ /Data\s+:/)
        iResult = (iResult)[/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
      end
      reality = {}
      if mResult[0] != 0
        reality = iResult
      else
        reality = Hash[*iResult.collect {|w| w.chomp.strip.split(/\s+/)}.select do |w|
                    expected.has_key?(w[0]) && ((w[1] !~ expected[w[0]]['hard']) || (w[2] !~ expected[w[0]]['soft']))
                  end.collect do |w|
                    [w[0], {'hard' => {"IS" => w[1], "SB" => expected[w[0]]['hard']}, 'soft' => {"IS" => w[2], "SB" => expected[w[0]]['soft']}}]
                  end.flatten]
      end

      [mResult[0], reality]
    end
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].empty?
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      skipMessage + "[#{Model::TARGETHOST.architecture}]"
      mcaller.badones = {'launchd limits check' => {}}
      messages = {}
      if data[0] != 0
        messages['launchctl'] = {"IS" => data[1], "SB" => "launchctl limit successful"}
      else
        messages = data[1]
      end
      mcaller.badones['launchd limits check'] = messages
    end
  end,
  
  v(cb("sysctl limits check") do 
    if(Model::TARGETHOST.architecture != 1 &&
       Model::TARGETHOST.architecture != 9 &&
       Model::TARGETHOST.architecture != 39)
      [0, {}]
    else
      expected = {'kern' => {'maxfiles'        => Model::TARGETHOST.architecture == 39 ? '524288' : '524289',
                             'maxfilesperproc' => '524288',
                             'maxproc'         => '2048',
                             'maxprocperuid'   => '2048'
                            }
                 }
      reality = {}
      exitCode = 0
      expected.each_key do |key|
        mObject = RunCommand.new('/usr/sbin/sysctl', 'root', key)
        mResult = mObject.run
        iResult = mResult[1]
        if mResult[0] != 0
          exitCode += 1
          if(iResult =~ /Data\s+:/)
            iResult = (iResult)[/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
          end
          reality = {key => iResult}
        else
          result = Hash[*iResult.split("\n").select do |w|
                            w =~ /#{key}\.[^\:\s]+[:\s]=?\s+/
                          end.collect do |w|
                            toks = w.chomp.strip[/#{key}\.(.*)/, 1].split(/\s+=\s+/)
                            toks << "Missing" if toks.size == 1
                            toks
                          end.select do |w|
                            expected[key].has_key?(w[0]) && (w[1] != expected[key][w[0]])
                          end.collect do |w|
                            [w[0], {"IS" => w[1], "SB" => expected[key][w[0]]}]
                          end.flatten]
          reality[key] = result if !result.empty?
        end
      end
      [exitCode, reality]
    end
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1] == {}
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      skipMessage + "[#{Model::TARGETHOST.architecture}]"
      mcaller.badones = {'sysctl limits check' => {}}
      messages = {}
      if data[0] != 0
        messages['sysctl'] = {"IS" => data[1], "SB" => "sysctl limit successful"}
      else
        messages = data[1]
      end
      mcaller.badones['sysctl limits check'] = messages
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