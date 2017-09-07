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
require "#{mypath}/install/configparser"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Server mysql config check"

include Action 

mandatory = {'skip_external_locking' => 'OFF',
             'have_openssl' => 'YES',
             'have_ssl' => 'DISABLED',
             'innodb_data_file_path' => 'ibdata1:10M:autoextend',
             'innodb_flush_log_at_trx_commit' => '0',
             'general_log_file' => File.join(Command::ZIMBRAPATH, 'log', 'mysql-mailboxd.log'),
            }
mapping = {'pid-file' => 'pid_file',
           'log-slow-queries' => 'log_slow_queries',
           'long-query-time' => 'long_query_time',
           'table_cache' => 'table_open_cache',
          }
exceptions = {'basedir' => Utils::Test.new('is =~ sb') {|sb, is| sb.index(Command::ZIMBRAPATH) == 0},
              'bind-address' => Utils::Test.new('is =~ sb') {|sb, is| sb =~ /(127\.0\.0\.1|localhost|::1)/},
              'datadir' => Utils::Test.new('is =~ sb') {|sb, is| is =~ /#{sb}\/?/},
              'err-log' => Utils::Test.new('is =~ sb') {|sb, is| true},
              'innodb_buffer_pool_size' => Utils::Test.new('is <= sb') {|sb, is| is.to_i <= sb.to_i},
              'innodb_log_buffer_size' => Utils::Test.new('is <= sb') {|sb, is| is.to_i <= sb.to_i},
              'innodb_max_dirty_pages_pct' => Utils::Test.new('is <= sb') {|sb, is| is.to_f == sb.to_f},
              'log-short-format' => Utils::Test.new('ON') do |sb, is|
                                      sb = nil if sb == 'FALSE'
                                      is == sb
                                    end,
              'log-slow-queries' => Utils::Test.new('ON') {|sb, is| is == "ON"},
              'long-query-time' => Utils::Test.new('is == sb') {|sb, is| is.to_f == sb.to_f},
              'pid-file' => Utils::Test.new('is == sb') {|sb, is| is == sb},
              'query_cache_type' => Utils::Test.new('is >= sb') do |sb, is|
                                      if sb.to_i == 0
                                        is == 'OFF'
                                      elsif sb.to_i == 1
                                        is == 'ON'
                                      else
                                        is == 'DEMAND'
                                      end
                                    end ,
              'read_buffer_size' => Utils::Test.new('is <= sb') {|sb, is| is.to_i <= sb.to_i},
              'slow_query_log' => Utils::Test.new('is == sb') do |sb, is|
                                    if sb == '1'
                                      next is == 'ON'
                                    elsif sb == '0'
                                      next is == 'OFF'
                                    else
                                      next false
                                    end
                                  end,
              'sort_buffer_size' => Utils::Test.new('is <= sb') {|sb, is| is.to_i <= sb.to_i},
              'table_cache' => Utils::Test.new('range (sb - 100)-sb') {|sb, is| is.to_i >= (sb.to_i - 100) && is.to_i <= sb.to_i},
              'user' => Utils::Test.new('is >= sb') {|sb, is| true},
             }
hasMysql = ZMProv.new('gas', 'mailbox').run[1].include?(Model::TARGETHOST.to_s)
(mCfg = ConfigParser.new).run
 
#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

=begin
  current.action = [       
  mCfg.getServersRunning('store').map do |x|
  [
    v(cb("mySql config variables test") do
      mObject = RunCommand.new(File.join(Command::ZIMBRAPATH,'bin','mysql'),
                               Command::ZIMBRAUSER,
                               '-e "show variables\G"', h = Model::Host.new(x))
      data = mObject.run
      if(data[1] =~ /Data\s+:/)
          data[1] = (data[1])[/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
      end
      allVars = Hash[*data[1].split(/\n/).select {|w| w =~ /^\s*(Variable_name|Value).*/}.collect {|w| if w.split(/:\s+/)[1] == nil; "UNDEF"; else w.split(/:\s+/)[1].strip.chomp; end }]
      mObject = RunCommand.new('cat', Command::ZIMBRAUSER,
                               File.join(Command::ZIMBRAPATH,'conf','my.cnf'), h)
      data = mObject.run
      if(data[1] =~ /Data\s+:/)
          data[1] = (data[1])[/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
      end
      mResult = Hash[*data[1].split(/\n/).select {|w| w !~ /^\s*#/}.select {|w| w =~ /^.*=.*/}.collect {|w| w.chomp.strip}.collect {|w| w.split(/\s*([^=\s]+)\s*=\s*(\S*)\s*/)[1,2]}.flatten]
      [0, [allVars,mResult.merge(mandatory)]]
    end) do |mcaller, data|
      expected = data[1][1]
      reality = data[1][0]
      expected.delete('plugin-load')
      errors = expected.keys.select {|k| expected[k] != reality[k]}#.collect {|k| [k,reality[k], expected[k]]}
      mcaller.pass = data[0] == 0 && (errors - exceptions.keys - mapping.values).empty? &&
                     (errors & exceptions.keys).select do |k| 
                        if mapping.has_key? k
                          is = reality[mapping[k]]
                        else
                          is = reality[k]
                        end
                        !exceptions[k].call(expected[k], is)
                      end.empty?
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        diffs = {}
        (errors - exceptions.keys - mapping.values).select do |k|
          if reality.has_key?(k)
            diffs[k] = {"IS" => reality[k], "SB" => expected[k]}
          else
            diffs[k] = {"IS" => "Typo, non-existing option", "SB" => 'one of mysql options'}
            maybe = reality.keys.select {|w| w =~ /#{k}/}
            if maybe[0] != nil
              diffs[k]["SB"] = "One of [" + maybe.join(",") + "]"
            end
          end
        end
        (errors & exceptions.keys).select do |k| 
          if mapping.has_key? k
            is = reality[mapping[k]]
          else
            is = reality[k]
          end
          if !exceptions[k].call(expected[k], is)
            diffs[k] = {"IS" => is, "SB" => expected[k]}
          end
        end
        mcaller.suppressDump("Suppress dump, the result has #{data[1].size} lines") if data[1].size >= 100
        mcaller.badones = {x + ' - mysql config' => diffs}
      end
    end,
    
    v(cb("mySql config uniqueness test") do
      mObject = RunCommand.new(x, 'cat', Command::ZIMBRAUSER,
                               File.join(Command::ZIMBRAPATH,'conf','my.cnf',Model::Host.new(x)))
      data = mObject.run
      if(data[1] =~ /Data\s+:/)
          data[1] = (data[1])[/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
      end
      mCnf = Hash.new([])
      data[1].split(/\n/).select {|w| w =~ /^.*=.*/}.collect {|w| w[/^\s*(.*)\s*$/,1]}.each do |line|
        k, v = line.split(/\s+=\s+/)
        mCnf[k] = mCnf[k] + [v]
      end
      [0, mCnf]
    end) do |mcaller, data|
    mExceptions = {'pid-file' => 2}
    mExceptions.default = -1
      mcaller.pass = data[0] == 0 && data[1].select {|k, v| v.size > 1}.select {|k, v| v.size != mExceptions[k]}.empty?
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        diffs = {}
        data[1].each_pair do |k, v|
          diffs[k + " occurrences"] = {"IS" => v.size, "SB" => mExceptions[k]} if v.size > 1
        end
        mcaller.badones = {x + ' - uniqueness test' => diffs}
      end
    end,
    
    v(RunCommand.new(File.join(Command::ZIMBRAPATH,'bin','mysql'),
                     Command::ZIMBRAUSER,
                     '-e "select count(*) from mysql.user where password = \"\" OR password IS NULL\G"', Model::Host.new(x))) do |mcaller, data|
      mcaller.pass = data[0] == 0 && !data[1][/count\(\*\):\s+0/].nil?
      if(not mcaller.pass)
          class << mcaller
            attr :badones, true
          end
          mcaller.badones = {x + ' - mysql users without password' => {"IS" => data[1][/(count\(\*\):\s+\S+)/, 1], "SB"=> '0'}}
      end
    end,
  ]
  end,

 ]

=end

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