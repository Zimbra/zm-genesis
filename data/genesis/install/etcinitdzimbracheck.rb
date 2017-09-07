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
 
require "model" 
require "action/block"
require "action/runcommand" 
require "action/verify"
require "action/buildparser" 

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "/etc/init.d/zimbra test"

include Action

skipTest = false


#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [       
  
  v(cb("/etc/init.d/zimbra check") do 
    if BuildParser.instance.targetBuildId =~ /MACOSX/i
      [0, "Feature not applicable on MACOSX"]
    else
      path = File.join(Command::ZIMBRAPATH, 'libexec')
      mPath = File.join('/opt', 'zcs-installer', 'installbin')
      path = mPath if (RunCommand.new("/bin/ls","root","-l", File.join(mPath,'zimbra')).run.first rescue 2) == 0
      mObject = RunCommand.new("/usr/bin/cmp", "root", "/etc/init.d/zimbra", File.join(path, 'zimbra'))
      mResult = mObject.run
      if mResult[0] != 0
        iResult = mResult[1]
        if(iResult =~ /Data\s+:/)
          iResult = (iResult)[/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
        end
        [mResult[0], File.join(path, 'zimbra'), iResult]
      else
        mResult
      end
    end
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {"/etc/init.d/zimbra and #{data[1]} check" => {"IS"=>"#{data[2]}", "SB"=>"Equal"}}
    end
  end,
  
  v(cb("/etc/rc*.d/*zimbra check") do
    #TODO: suse has a different layout, skip the test for now
    if BuildParser.instance.targetBuildId =~ /MACOSX/i ||
       BuildParser.instance.targetBuildId =~ /SLES.*/  ||
       BuildParser.instance.targetBuildId =~ /SuSEES.*/
      skipTest = true
      [0, "Feature not applicable on #{BuildParser.instance.targetBuildId}"]
    else
      path = File.join(File::SEPARATOR, 'etc', 'rc*.d', '*zimbra')
      mResult = RunCommand.new("/bin/ls","root", '-l', path).run
      mResult[1] = Hash[*mResult[1].split("\n").collect{ |w| w.split(/\s+/)}.collect{ |w| [w[-3], w[-1]]}.flatten]
      mResult
    end
  end) do |mcaller, data|
    mandatory = ['/etc/rc0.d/K01zimbra',
                 '/etc/rc1.d/K01zimbra',
                 '/etc/rc3.d/S99zimbra',
                 '/etc/rc4.d/S99zimbra',
                 '/etc/rc5.d/S99zimbra',
                 '/etc/rc6.d/K01zimbra',
                ]
    optional = ['/etc/rc0.d/S89zimbra',
                '/etc/rc2.d/K01zimbra',
                '/etc/rc2.d/S99zimbra',
                '/etc/rc3.d/K01zimbra',
                '/etc/rc4.d/K01zimbra',
                '/etc/rc5.d/K01zimbra',
                '/etc/rc6.d/S89zimbra',
               ]
    mcaller.pass = skipTest || (data[0] == 0 &&
                   (data[1].keys & mandatory).length == mandatory.length &&
                   (data[1].keys - mandatory).select{|w| !optional.include?(w)}.empty?
                   data[1].values.uniq.length == 1 &&
                   data[1].values.first =~ /(\/etc|\.\.)\/init\.d\/zimbra/)
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      if data[0] != 0
        mcaller.badones = {"ls /etc/rc*.d/*zimbra exit code" => {"SB" => 0, "IS" => data[0]}}
      else
        missing = mandatory - data[1].keys
        unexpected = data[1].keys - mandatory - optional
        messages = {}
        (mandatory - data[1].keys).each do |file|
          messages[file] = {"SB" => 'found', "IS" => 'missing'}
        end
        (data[1].keys - mandatory - optional).each do |file|
          messages[file] = {"SB" => 'not found', "IS" => 'found'}
        end
        mcaller.badones = {"/etc/rc*.d/*zimbra check" => messages}
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