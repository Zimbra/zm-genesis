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

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
mypath = 'data'
if($0 =~ /data\/genesis/)
  mypath += '/genesis'
end

require "model"
#require 'model/env'
require "action/block"
require "action/runcommand" 
require "action/verify"
require "action/buildparser"
require "action/zmprov"
require "#{mypath}/install/configparser"
require "action/zmlocalconfig"
require 'socket'

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Server crash test"

include Action 
include Model


ldapUrls = []

#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [
  v(cb("server crash test", 2400) do
    exitCode = 0 
    result = []
    mObject = ConfigParser.new()
    mResult = mObject.run
    stores = mObject.getServersRunning('store')
    next([0, 'Skipping - no stores available in configuration']) if !stores
    stores.each do |host|
      myHost = Host.new(host[/(.*)\.#{Model::TestDomain}/, 1], Model::TestDomain)
      zshostname = ZMLocal.new(myHost, 'zimbra_server_hostname').run
      ip = IPSocket.getaddress(host)#Socket.gethostname)
      ['Pop3', 'Pop3SSL', 'Imap', 'ImapSSL'].each do |protocol|
      #['Pop3'].each do |protocol|
        mResult = RunCommandOn.new(myHost, 'zmprov', Command::ZIMBRAUSER,
                                   '-l gs', zshostname, "zimbra#{protocol}BindAddress").run
        backup = mResult[1][/zimbra#{protocol}BindAddress:\s+(.*)\s*/, 1]
        mResult = RunCommandOn.new(myHost, 'zmprov', Command::ZIMBRAUSER,
                                   'ms', zshostname, "zimbra#{protocol}BindAddress", ip).run
        mObject = RunCommandOn.new(myHost, File.join(Command::ZIMBRAPATH, 'bin', 'zmmailboxdctl'), Command::ZIMBRAUSER, 'stop', ';',
                                   'date', '+%c')
        mResult = mObject.run
        if(mResult[1] =~ /Data\s+:/)
          mResult[1] = mResult[1][/Data\s+:\s+([^\s}].*?)$\s+\}/m, 1]
        end
        startTime = DateTime.parse(mResult[1])
        mObject = RunCommandOn.new(myHost, File.join(Command::ZIMBRAPATH, 'bin', 'zmmailboxdctl'), Command::ZIMBRAUSER, 'start')
        mResult = mObject.run
        sleep 60
        mObject = RunCommandOn.new(myHost, 'grep', 'root', '-B 1', '-h', 
                                   "\"com.zimbra.common.service.ServiceException: system failure: Could not bind to port=\"",
                                   File.join(Command::ZIMBRAPATH, 'log', 'mailbox.log'))
        mResult = mObject.run
        if(mResult[1] =~ /Data\s+:/)
          mResult[1] = mResult[1][/Data\s+:\s+([^\s}].*?)$\s+\}/m, 1]
        end
        crashTime = begin
                      DateTime.parse(mResult[1].split(/\n/)[-2])
                    rescue
                      startTime - 1
                  end
        if crashTime >= startTime
          exitCode += 1
          result.push("#{host} zimbra#{protocol}BindAddress - #{mResult[1].split(/\n/)[-2,2]}")
        end
        mObject = RunCommandOn.new(myHost, 'zmprov', Command::ZIMBRAUSER,
                                   '-l ms', zshostname, "zimbra#{protocol}BindAddress", "\"#{backup}\"")
        mResult = mObject.run
        mObject = RunCommandOn.new(myHost, File.join(Command::ZIMBRAPATH, 'bin', 'zmmailboxdctl'), Command::ZIMBRAUSER,
                                   'restart')
        mResult = mObject.run
      end
    end
    [exitCode, result]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0
    if (not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'server crash check' => {"IS"=>data[1], "SB"=>'mailbox running'}}
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