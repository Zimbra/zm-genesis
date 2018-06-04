#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2008 Yahoo
#
# Test zmmtactl star, stop, reload
#
if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "action/command"
require "action/clean"
require "action/block"
require "action/zmprov"
require "action/verify"
require "action/runcommand"
require "model"
require "action/zmamavisd"


include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmmtactl"

#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [

  v(ZMMtactl.new) do |mcaller, data|
    mcaller.pass = (data[0] == 1)&& data[1].include?('/opt/zimbra/bin/zmmtactl start|stop|restart|reload|status')
  end,
 v(ZMMtactl.new('start'), 240) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('Rewriting configuration files...done.')\
                                  && data[1].include?('Starting saslauthd...already running.')
  end,

  v(ZMMtactl.new('start'), 240) do |mcaller, data|
   mcaller.pass = (data[0] == 0) && data[1].include?('Rewriting configuration files...done.')\
                                 && data[1].include?('Starting saslauthd...already running.')
  end,

  v(ZMMtactl.new('status')) do |mcaller, data|
    mcaller.pass = (data[0] == 0)
  end,

  if !Model::Servers.getServersRunning('mta').include?(Model::TARGETHOST.to_s)
  [
    v(RunCommand.new('sed', 'root', '-i.bak', '-e', "\"s/^\\(Defaults[ \\t].*env_reset.*\\)$/\\1, passwd_timeout=1/\"", '/etc/sudoers')) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1].empty?
    end,
    
    v(cb("stuck test") do
      start =Time.now
      mResult = RunCommand.new('zmmtactl', Command::ZIMBRAUSER, 'status').run
      stop = Time.now
      mResult.push(stop - start)
    end) do |mcaller, data|
      mcaller.pass = data[0] != 0 && data[1] =~ /Error: postfix not installed/ && data.last < 60
    end,
    
    v(RunCommand.new('sed', 'root', '-i.bak', '-e', "\"s/^\\(\\(Defaults[ \\t]*env_reset\\).*\\)/\\2/\"", "/etc/sudoers")) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1].empty?
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
