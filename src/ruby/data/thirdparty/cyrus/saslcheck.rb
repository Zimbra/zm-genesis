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
# Check SASL library
if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model" 
require "action/block"
require "action/runcommand" 
require "action/verify"
#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Sasl library check" 

include Action 

 
#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [       
  
  # Get a list of executables   
  v(cb("Sasl library check") do 
    result = [0, []]
    dirList =  (Action::RunCommand.new('ls','root',
                                       File::join(Command::ZIMBRACOMMON, '/lib/sasl2', "*")).run)[1].split(/\n/)
    result[1].push(['entries', dirList])
    ['gssapi', 'plain', 'login', 'anonymous', 'crammd5', 'digestmd5', 'otp'].each do |library|
        result[1].push([library, library]) unless dirList.any? {|x| x.include?(library) }
    end
    result
  end) do |mcaller, data|  
  mcaller.pass = data[0] == 0 && data[1].size < 2
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'Sasl Test' => {}}
      data[1].each do |elem|
        mcaller.badones['Sasl Test'][elem[0].split(',')[0]] = {"IS" => elem[1]}
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
