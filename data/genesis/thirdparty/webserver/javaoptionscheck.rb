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
require "action/zmprov"
require "action/zmlocalconfig"
require "action/zmamavisd.rb"
require "action/buildparser"
require "#{mypath}/install/configparser"
require "#{mypath}/install/utils"
require 'rexml/document'
include REXML

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Webserver java options test"

include Action


expected = ['-Dfile.encoding=UTF-8',
            '-server',
            '-Djava.awt.headless=true',
            '-Dsun.net.inetaddr.ttl=60',
            '-XX:+UseConcMarkSweepGC',
            '-XX:SoftRefLRUPolicyMSPerMB=1',
            '-verbose:gc',
            '-XX:+PrintGCDetails',
            '-XX:+PrintGCDateStamps',
            '-XX:+PrintGCApplicationStoppedTime',
            '-XX:-OmitStackTraceInFastThrow',
            "-Xmx#{ZMLocal.new('mailboxd_java_heap_size').run}m",
            "-Xmn#{ZMLocal.new('mailboxd_java_heap_size').run.to_i * ZMLocal.new('mailboxd_java_heap_new_size_percent').run.to_i / 100}m",
            "-Xms#{ZMLocal.new('mailboxd_java_heap_size').run}m",
            "-Xss#{ZMLocal.new('mailboxd_thread_stack_size').run}",
            "-Dorg.apache.jasper.compiler.disablejsr199=true",
            "-Xloggc:#{File.join(Command::ZIMBRAPATH, 'log', 'gc.log')}",
            "-XX:-UseGCLogFileRotation",
            "-XX:NumberOfGCLogFiles=20",
            "-XX:GCLogFileSize=4096K",
]
isRelease = RunCommand.new('ls', 'root', File.join(Command::ZIMBRAPATH, '.uninstall', 'packages', 'zimbra-core*')).run[1] =~ /GA/
#expected.push('-ea') if !isRelease
(mCfg = ConfigParser.new).run
ipMode = XPath.first(mCfg.doc, "//host[@name='#{Model::TARGETHOST.to_str}']/option[@name='zimbraIPMode']").text rescue nil
expected.push('-Djava.net.preferIPv4Stack=true') if ipMode == 'ipv4' || ipMode == nil
expected.push('-Djava.net.preferIPv6Stack=true') if ipMode == 'ipv6'
expected.push("-Dhttps.protocols=TLSv1,TLSv1.1,TLSv1.2", "-Djdk.tls.client.protocols=TLSv1,TLSv1.1,TLSv1.2") if !Utils::isUpgradeFrom('8\.[05]\.')
# the following option is present if emma is installed 
expected.push('-XX:-UseSplitVerifier') if ZMLocalconfig.new('mailboxd_java_options',
                                                            Model::Host.new(mCfg.getServersRunning('store').first)).run[1] =~ /-XX:-UseSplitVerifier/

#
# Setup
#
current.setup = [

]
#
# Execution
#

current.action = [
  v(cb("Webserver java options") do
    mObject = ZMProv.new('gas', 'mailbox')
    mResult = mObject.run
    mboxServers = mResult[1]
    if(mboxServers =~ /Data\s+:/)
      mboxServers = mboxServers[/Data\s+:\s+([^\s}].*?)$\s*\}/m, 1]
    end
    mObject = RunCommandOn.new(mboxServers.split(/\s+/).first, 'ps auxww | grep zmmailboxdmgr | grep -v grep', 'root')
    mResult = mObject.run
    if(mResult[1] =~ /Data\s+:/)
      mResult[1] = mResult[1][/Data\s+:\s+([^\s}].*?)$\s*\}/m, 1]
    end
    mResult[1] = mResult[1][/.*zmmailboxdmgr\s+start\s+(.*)/, 1].chomp
    mResult
  end) do |mcaller, data|
    unexpected = []
    mcaller.pass = data[0] == 0 && (missing = expected - data[1].split(/\s+/)).empty? &&
                   (unexpected = data[1].split(/\s+/) - expected).empty?
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'Webserver java options check' => {}}
      if !missing.empty?
        mcaller.badones = {'Webserver java options check' => {"IS" => "Missing or changed [#{data[1]}]", "SB"=>"#{missing.join(" ")}"}}
      end
      if !unexpected.empty?
        mcaller.badones['Webserver java options check'].merge!({"IS" => "#{unexpected.join(" ")}", "SB" => "Missing"})
      end
    end
  end,

  mCfg.getServersRunning('store').select {|w| 'yes' == XPath.first(mCfg.doc, "//host[@name='#{w}']//option[@name='SERVICEWEBAPP']").text rescue 'yes'}.map do |x|
  [
    v(cb("-ea option set") do
      mResult = RunCommand.new('ps auxww | grep zmmailboxdmgr | grep -v grep', 'root', h = Model::Host.new(x)).run
      mResult[1] = mResult[1][/.*zmmailboxdmgr\s+(start.*)/m, 1].chomp
      if mResult[1].index(/\s-ea\s/).nil?
        mResult = RunCommand.new('zmlocalconfig', Command::ZIMBRAUSER, '-m nokey', 'mailboxd_java_options', h).run
        mData = mResult[1].chomp + ' -ea'
        mResult = RunCommand.new('zmlocalconfig', Command::ZIMBRAUSER, '-e', "mailboxd_java_options=\"#{mData.gsub("$", "\\$")}\"", h).run
        next mResult
      elsif isRelease
        # if the build is a release candidate, "-ea" must not be present
        next [1, mResult[1][/start\s+(.*)/, 1]]
      end
      mResult
    end) do |mcaller, data|
      mcaller.pass = data[0] == 0
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {x + ' - java option set' => {"IS" => data[1], "SB" => "no -ea"}}
      end
    end,

    RunCommand.new('zmmailboxdctl', Command::ZIMBRAUSER, 'restart', h = Model::Host.new(x)),

    ZMMailboxdctl.waitForJetty(h),
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
