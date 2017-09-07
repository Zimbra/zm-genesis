#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2010 Zimbra 
#
#
# check openssl LD_RUN_PATH

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
require "action/buildparser"
require 'action/oslicense'
require "#{mypath}/install/configparser"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "clamav run path test"

include Action 

unexpected = Regexp.new("\s+libltdl\.")
#extension = '.so'
cmd = 'ldd'
mConfig = ConfigParser.new()
mConfig.run

#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [       
  mConfig.getServersRunning('mta').map do |x|
    v(cb("clamav runpath test") do 
      if BuildParser.instance.targetBuildId =~ /MACOSX/i
        extension = '.dylib'
        cmd = 'otool -L'
      end
      mObject = RunCommand.new(cmd, Command::ZIMBRAUSER,
                               File.join(Command::ZIMBRAPATH,'clamav', 'sbin', "clamd"), Model::Host.new(x))
      mResult = mObject.run[1]
      #puts mResult
      if mResult.split(/\n/).select {|w| w =~ /\s*#{unexpected}.*/}.empty?
        [0, mResult[/\s*#{unexpected}.*/]]
      else
        if(mResult =~ /Data\s+:/)
          mResult = (mResult)[/Data\s+:\s+(.*?)\s*\}/m, 1]
        end
        [1, ["ldd/otool " + File.join(Command::ZIMBRAPATH,'clamav', 'sbin', "clamd"), 
             mResult[/.*(#{unexpected}.*)$/], "! #{unexpected.source}"]]
      end
    end) do |mcaller, data|
      mcaller.pass = data[0] == 0
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {x + ' - clamav run path test' => {data[1][0] => {"IS"=>data[1][1], "SB"=>data[1][2]}}}
      end
    end
  end,
    
  ]
  
=begin 
  mConfig.getServersRunning('mta').map do |x|
    v(RunCommand.new('grep', Command::ZIMBRAUSER, 'dependency_libs=',
                     File.join(Command::ZIMBRAPATH,'clamav', 'lib*', "libclam*.la"), Model::Host.new(x)) do
    end) do |mcaller, data|
      mcaller.pass = data[0] == 0 &&
                     (lines = data[1].split(/\n/)).size > 0 &&
                     (dependency = Hash[*lines.select do |w|
                                           w =~ /sendmail-/
                                         end.collect do |w|
                                           toks = w.split(':')
                                           [toks.first, toks.last[/(sendmail-\S+)/, 1]]
                                         end.flatten]).size == lines.size &&
                     dependency.keys.select {|w| dependency[w] !~ /sendmail-#{OSL::LegalApproved['sendmail']}/}.empty?
    end
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