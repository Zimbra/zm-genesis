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
# Test zmantispasm star, stop, restart
#
if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

mypath = 'data'
if($0 =~ /data\/genesis/)
  mypath += '/genesis'
end

require "action/command"
require "action/clean"
require "action/block"
require "action/zmprov"
require "action/verify"
require "action/runcommand"
require "model"
require "action/zmamavisd"
require "action/zmlocalconfig"
require "#{mypath}/install/utils"


include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmantispamctl"

myHost = (vals = ['127.0.0.1', Utils::zimbraHostname])[rand(vals.length)]

#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [
  v(ZMAntispam.new('start'), 240) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('Starting amavisd...amavisd is already running.')
  end,

  v(ZMAntispam.new('status')) do |mcaller, data|
    mcaller.pass = (data[0] == 0)
  end,

  v(ZMAntispam.new('stop')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('Stopping amavisd... done.')
  end,

  v(ZMAntispam.new('start'), 240) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('Starting amavisd...done.')
  end,

  v(ZMAntispam.new('start')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('amavisd is already running.')
  end,

  v(ZMAntispam.new('reload'), 240) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('Stopping amavisd... done.')&& data[1].include?('Starting amavisd...done.')
  end,

  v(ZMAntispam.new('stop')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('Stopping amavisd... done.')
  end,

  v(ZMAntispam.new('stop')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('Stopping amavisd...amavisd is not running.')
  end,

  v(ZMAntispam.new('restart'), 240) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('Stopping amavisd...amavisd is not running.') && data[1].include?('Starting amavisd...done.')
  end,

  v(ZMAntispam.new('restart'), 240) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('Stopping amavisd... done.') && data[1].include?('Starting amavisd...done.')
  end,

  v(ZMAntispam.new) do |mcaller, data|
    mcaller.pass = (data[0] == 1) && data[1].include?('zmantispamctl start|stop|restart|reload|status')
  end,
  
  Action::ZMLocalconfig.new('-e', 'antispam_mysql_enabled=TRUE'),
  #Action::ZMLocalconfig.new('-e', 'antispam_mysql_host=foo'),
  #v(ZMAntispam.new('restart'), 240) do |mcaller, data|
  #  if(data[1] =~ /Data\s+:/)
  #    data[1] = data[1][/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
  #  end
  #  mcaller.pass = data[0] == 0 && data[1].split(/\n/) == ['Stopping amavisd... done.', 'Starting amavisd...done.']
  #end,
  
  Action::ZMLocalconfig.new('-e', "antispam_mysql_host=#{myHost}"),
  v(ZMAntispam.new('restart'), 240) do |mcaller, data|
    if(data[1] =~ /Data\s+:/)
      data[1] = data[1][/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
    end
    #puts YAML.dump(data[1].split(/\n/))
    mcaller.pass = data[0] == 0 && 
                   data[1].split(/\n/) & (expected = ['Stopping amavisd... done.', 'Starting amavisd...done.', '* Starting antispam mysql server ...done.']) == expected
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {"#{myHost} - antispam restart check" => {"IS"=>data[1], "SB"=>'Success'}}
    end
  end,
    
  v(RunCommand.new(File.join(Command::ZIMBRAPATH,'bin','antispam-mysql'), Command::ZIMBRAUSER,
                   '-e "show variables where variable_name like \"innodb_data_file_path\" ' +
                   'or variable_name like \"general_log_file\"\G"', h = Model::Host.new(myHost))) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1]  =~ /^\s+Value: ibdata1:10M:autoextend$/ &&
                   data[1]  =~ /^\s+Value: #{File.join(Command::ZIMBRAPATH, 'log', 'mysql-antispam.log')}$/
  end,

  Action::ZMLocalconfig.new('-u', 'antispam_mysql_enabled'),
  v(ZMAntispam.new('restart'), 240) do |mcaller, data|
    if(data[1] =~ /Data\s+:/)
      data[1] = data[1][/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
    end
    mcaller.pass = data[0] == 0 &&
                   data[1].split(/\n/) & (expected = ['Stopping amavisd... done.', 'Starting amavisd...done.', 'Stopping mysqld for anti-spam... done.']) == expected
  end,
  # to complete cleanup:
  # rm -rf /opt/zimbra/conf/antispam-my.cnf 
  # rm -rf /opt/zimbra/data/amavisd/mysql/data
  
  

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
