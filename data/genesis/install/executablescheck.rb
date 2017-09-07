#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2008 Zimbra
#
# Check that executables use /opt/zimbra/java symbolic link to point to JAVA_BINARY

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "model" 
require "action/block"
require "action/runcommand" 
require "action/verify"
#require "action/zmcontrol"
require 'model/deployment'

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Executables check" 

include Action 

#(mCfg = ConfigParser.new).run
 
#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [       
  #mCfg.getAllServers.map do |x|
  Model::Deployment.getServersRunning('*').map do |x|
  [
    # Get a list of non executables
    v(cb("Non Executables check") do 
      result = [0, []]
      ['libexec',
       'bin'].each do |dir|
        mResult = RunCommand.new('find', 'root',
                                   File::join(Command::ZIMBRAPATH, dir) + File::SEPARATOR,
                                   '-maxdepth 1', '! -executable', '-type f', '-print', Model::Host.new(x)).run
        next mResult if mResult[0] != 0
        mResult[1].split(/\n/).each do |f|
          crt = RunCommandOn.new(x, 'file', 'root', f).run
          result[0] += 1
          result[1] << crt[1].chomp.split(/:\s+/)
        end
      end
      result
    end) do |mcaller, data|  
    mcaller.pass = data[0] == 0 && data[1].empty?
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {x + ' - Executables test' => {}}
        data[1].each do |elem|
          mcaller.badones[x + ' - Executables test'][elem[0]] = {"IS" => elem[1], "SB" => 'executable'}
        end
      end
    end,
      
    # Check syntax of executables
    ['libexec', 'bin'].map do |dir|
    [
      RunCommand.new('find', 'root', File::join(Command::ZIMBRAPATH, dir) + File::SEPARATOR,
                     '-maxdepth 1', '-executable', '-type f', '-print', Model::Host.new(x)).run[1].split(/\n/).map do |f|
      [
        v(cb("#{f} check") do
          mResult = RunCommand.new('head', Command::ZIMBRAUSER, '-1', f, h = Model::Host.new(x)).run
          if (mType = mResult[1].encode('US-ASCII', 'UTF-8', {:invalid => :replace, :undef => :replace, :replace => '??'})) =~ /perl/
            #mChecker = ['perl -c', '-I', File.join(Command::ZIMBRAPATH, 'zimbramon', 'lib'), mType[/perl\s+(.+)$/, 1]].compact.join(' ')
            mChecker = ['perl -c', '-I', File.join(Command::ZIMBRACOMMON, 'lib', 'perl5')].compact.join(' ')
          elsif mType =~ /bash/
            mChecker = 'bash -n'
          else
            next [0, 'skip']
          end
          RunCommand.new(mChecker, dir == 'bin' ? Command::ZIMBRAUSER : 'root', f, h).run
        end) do |mcaller, data|  
          mcaller.pass = data[0] == 0 #&& data[1].empty?
        end,
      ]
      end
    ]
    end
  ]
  end
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