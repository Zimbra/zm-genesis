#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2009 Zimbra
#
# check that the required perl modules are present

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
require "#{mypath}/install/configparser"
require 'action/oslicense'

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Perl modules presence test"

include Action 

extras = ['DBD::SQLite']
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
  v(cb("modules test") do
    mObject = RunCommand.new('find /opt/zimbra/libexec/ ! -name "*.p[ml]" -type f -print | xargs file | grep perl', 'root')
    mResult = mObject.run
    files = mResult[1].split(/\n/).select {|w| w=~ /.*perl script/}.collect {|w| w.split(/:\s+/)[0].strip.gsub('//', '/')}
    ['/opt/zimbra/libexec/zmmon',
     '/opt/zimbra/libexec/zmgengraphs'].each {|f| files.delete(f)}
    mObject = RunCommand.new('find /opt/zimbra/bin/ ! -name "*.p[ml]" -print | xargs file | grep perl', 'root')
    mResult = mObject.run
    files += mResult[1].split(/\n/).select {|w| w=~ /.*perl script/}.collect {|w| w.split(/:\s+/)[0].strip.gsub('//', '/')}
    modules = []
    [files.join(' ')].each do |f|
      mObject = RunCommand.new('cat', Command::ZIMBRAUSER, f)
      mResult = mObject.run
      modules += mResult[1].split(/\n/).select {|w| w !~ /^\s*#/}.select {|w| w !~ /print/}.select {|w| w =~ /\s+\b(use\s+[A-Z].*|require[^"'])\b[^\$]*;/}.collect {|w| w[/.*\b(use|require)\b\s+([^};]*).*$/, 2].sub(/"(.+)"/,'qw(\1)').sub(/'(.+)'/,'qw(\1)').strip}
    end
    exitCode = 0
    res = {}
    modules = modules.uniq
    modules.select {|w| w.split(/\s+/).length != 1}.collect {|m| modules.delete(m.split(/\s+/)[0])}
    next([0, 'no perl modules found']) if modules.length == 0
    perl = 'perl'
    if (Model::TARGETHOST.architecture == 1 || Model::TARGETHOST.architecture == 9 || Model::TARGETHOST.architecture == 39)
      modules.delete('POSIX qw(strftime)')
    end
    modules += extras
    #delete the following to prevent Prototype mismatch: sub main::strftime error on rhel4u2
    modules.delete('Date::Format')
    modules.delete('Win32::Console::ANSI')
    mObject = RunCommand.new(perl, Command::ZIMBRAUSER, '-e', "\"use #{modules.join('; use ')}\"")
    mResult = mObject.run
    if mResult[0] != 0
      if(mResult[1] =~ /Data\s+:/)
        mResult[1] = (mResult[1])[/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
      end
      m = mResult[1][/Can't locate ([^\s]+)\.\S+ in @INC/, 1]#.gsub("/", "::")
      res[m] = mResult[1]
      exitCode += mResult[0]
    end
    # when command gets too long, check one (possibly several) module at a time
    #modules.uniq.each do |m|
    #  mObject = RunCommand.new('cd /opt/zimbra; perl', Command::ZIMBRAUSER, '-e', "\"use #{m}\"")
    #  mResult = mObject.run
    #  exitCode += mResult[0]
    #  if mResult[0] != 0
    #    if(mResult[1] =~ /Data\s+:/)
    #      mResult[1] = (mResult[1])[/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
    #    end
    #    res[m] = mResult[1] 
    #  end
    #end
    [exitCode, res]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 #&& result == expected
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      errs = {}
      data[1].each_pair {|k, v| errs[k] = {"IS"=>v.split(/\n/)[0].strip, "SB"=> "Found"}}
      mcaller.badones = {'Perl modules check' => errs}
    end
  end,
  
  mCfg.getServersRunning('store').map do |x|
    v(cb("modules test") do
      exitCode = 0
      res = {}
      mObject = RunCommand.new('cd libexec/scripts; perl', Command::ZIMBRAUSER,
                               '-e', "\"use Migrate; Migrate::runSqlParallel(1, \\\"show tables\\\")\"",
                               Model::Host.new(x))
      mResult = mObject.run
      if mResult[0] != 0
        if(mResult[1] =~ /Data\s+:/)
          mResult[1] = (mResult[1])[/Data\s+:\s*([^\s\.}].*?)\s*\}/m, 1]
        end
        m = mResult[1][/Can't locate (.*) in @INC/m, 1]
        res[m] = mResult[1]
        exitCode += mResult[0]
      end
      [exitCode, res]
    end) do |mcaller, data|
      mcaller.pass = data[0] == 0
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        errs = {}
        data[1].each_pair {|k, v| errs[k] = {"IS"=>v.split(/\n/)[0].strip, "SB"=> "Found"}}
        mcaller.badones = {x + ' - Migrate.pm check' => errs}
      end
    end
  end,
  
  OSL::Modules.keys.map do |x|
  [
    v(cb("module check") do
      mResult = RunCommand.new('perl', Command::ZIMBRAUSER,
                               '-e "use ' + x + '; print \\$INC{\"' + x.gsub('::', '/') + '.pm\"}"').run
      next [1, OSL::LegalApproved[OSL::Modules[x]]] if mResult[0] == 0 && mResult[1] !~ /#{Command::ZIMBRAPATH}/
      mResult = RunCommand.new('perl', Command::ZIMBRAUSER,
                               '-e "use ' + x + '; print \\$' + x + '::VERSION"').run
    end) do |mcaller, data|
      result = data[1][/(\d+(\.\d+)+)/, 1]
      mcaller.pass = data[0] == 0 && result == OSL::LegalApproved[OSL::Modules[x]] ||
                     data[0] != 0 && data[1] =~ /#{OSL::LegalApproved[OSL::Modules[x]]}/
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {"#{x} version" => {"IS" => data[0] != 0 ? data[1] : result, "SB" => OSL::LegalApproved[OSL::Modules[x]]}}
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
