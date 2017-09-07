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
# check openssl LD_RUN_PATH

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
current.description = "openSSL run path test"

include Action 

expected = Regexp.new(".*/opt/zimbra/common/lib.*/libcrypto..*")
extension = '.so.1.0.0'
cmd = 'ldd'

#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [       
  
  v(cb("openSSL runpath test") do 
    if BuildParser.instance.targetBuildId =~ /MACOSX/i
      extension = '.dylib'
      cmd = 'otool -L'
    end
    mObject = RunCommand.new(cmd, Command::ZIMBRAUSER,
                             File.join(Command::ZIMBRACOMMON,'lib', "libssl#{extension}"))
    mResult = mObject.run[1]
    if !mResult.split(/\n/).select {|w| w =~ /\s*#{expected}\s+.*/}.empty?
      [0, mResult[/\s*#{expected}\s+.*/]]
    else
      if(mResult =~ /Data\s+:/)
        mResult = (mResult)[/Data\s+:\s+(.*?)\s*\}/m, 1]
      end
      [1, ["ldd " + File.join(Command::ZIMBRACOMMON,'lib', "libssl#{extension}"), 
           mResult[/.*libcrypto\..*$/], expected.source]]
    end
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'openSSL run path test' => {data[1][0] => {"IS"=>data[1][1], "SB"=>data[1][2]}}}
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