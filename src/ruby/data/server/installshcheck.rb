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
# check install script 

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"  
require "action/runcommand"
require "action/verify"
require "action/block"
require "action/zmlicense"
require "action/zmprov"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Install script check"

include Action 

def checkIPv4Validity(ip, valid)
  v(RunCommand.new('source', 'root', File.join(Command::ZIMBRAPATH,'.uninstall','util','utilfunc.sh'),
                   '; verifyIPv4', ip)) do |mcaller, data|
    mcaller.pass = data[0] == (valid ? 0: 1)
  end
end

usage = [Regexp.escape('./install.sh [-r <dir> -l <file> -a <file> -u -s -c type -x -h] [defaultsfile]'),
         Regexp.escape('-c|--cluster type       Cluster install type active|standby.'),
         Regexp.escape('-h|--help               Usage'),
         Regexp.escape('-l|--license <file>     License file to install.'),
         Regexp.escape('-a|--activation <file>  License activation file to install. [Upgrades only]'),
         Regexp.escape('-r|--restore <dir>      Restore contents of <dir> to localconfig'),
         Regexp.escape('-s|--softwareonly       Software only installation.'),
         Regexp.escape('-u|--uninstall          Uninstall ZCS'),
         Regexp.escape('-x|--skipspacecheck     Skip filesystem capacity checks.'),
         Regexp.escape('--beta-support          Allows installer to upgrade Network Edition Betas.'),
         Regexp.escape('--platform-override     Allows installer to continue on an unknown OS.'),
         Regexp.escape('--skip-activation-check Allows installer to continue if license activation checks fail.'),
         Regexp.escape('--skip-upgrade-check    Allows installer to skip upgrade validation checks.'),
         Regexp.escape('[defaultsfile]          File containing default install values.'),
         Regexp.escape('--force-upgrade         Force upgrade to be set to YES. Used if there is package installation failure for remote packages.')
        ]

#
# Setup
#
current.setup = [
   
]

#
# Execution
#
current.action = [  
   
  v(RunCommand.new('file', Command::ZIMBRAUSER, File.join(Command::ZIMBRAPATH,'libexec','installer','install.sh'))) do |mcaller, data|
    mcaller.pass = data[1] =~ /script.*\s+text/
  end,
  
  ['0.0.0.0', '1.0.0.0.0',
   '1.0.0', '2.0', '3',
   '256.0.0.0', '260.0.0.0', '300.0.0.0',
   '10.256.0.0', '10.271.0.0', '10.412.0.0',
   '10.137.256.0', '10.137.534.0',
   '10.137.244.656'
  ].map do |x|
     checkIPv4Validity(x, false)
  end,
  
  ['1.0.0.0', '254.0.0.0', '255.0.0.0',
   '10.23.0.0', '10.254.0.0', '10.255.0.0',
   '10.137.45.0', '10.137.255.0',
   '10.137.244.67', '10.137.244.254', '10.137.244.255'
  ].map do |x|
     checkIPv4Validity(x, true)
  end,
    
  ['h', '-help'].map do |x|
    v(RunCommand.new('cd', 'root', File.join(Command::ZIMBRAPATH,'libexec','installer'),';./install.sh', '-' + x)) do |mcaller,data|
      mcaller.pass = data[0] == 0 &&
                     (lines = data[1].split(/\n/).select {|w| w !~ /^\s*$/}).size == usage.size - 1 &&
                     lines.select {|w| w !~ /#{usage.join('|')}/}.empty?
    end
  end,

  ([('a'..'z'),('A'..'Z')].map{|i| i.to_a}.flatten - ['a', 'c', 'h', 'l', 'r', 's', 'u', 'x']).map do |x|
    v(RunCommand.new('cd', 'root', File.join(Command::ZIMBRAPATH,'libexec','installer'),';./install.sh', '-' + x)) do |mcaller,data|
      mcaller.pass = data[0] == 0 &&
                     (lines = data[1].split(/\n/).select {|w| w !~ /^\s*$/}).size == usage.size &&
                     lines.select {|w| w !~ /(#{usage.join('|')}|ERROR: Unknown option\s-#{x})/i}.empty?
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {'install.sh unknown option' => {"IS"=>data[1] + data[2], "SB"=>'ERROR: Unknown option -' + x}}
      end
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