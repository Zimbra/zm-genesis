#!/usr/bin/ruby -w
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2006 Zimbra
#
# Server file permission check
# This test checks for correctness of the file permissions
# 

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 

require "model" 
require "action/block"
require "action/runcommand" 
require "action/verify"
require "action/zmcontrol"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Server file permission test"
if(Model::TARGETHOST.architecture == 1 || Model::TARGETHOST.architecture == 9)
  printOption = '-print' 
else
  printOption = '-printf "%p %m\n"' 
end

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
  v(cb("Zimbra User Permission Check") do
    mObject = Action::RunCommand.new('find','root', Command::ZIMBRAPATH, 
    " -user zimbra -perm +002 -type f  #{printOption}").run 
    [ 
     '/opt/zimbra/\.bash_history',
     '.*?catalina.out',
     ].each do |x| 
      mObject[1].gsub!(Regexp.new(x),'')
    end
    mObject
  end) do |mcaller, data|  
    mcaller.pass = data[0] == 0 && !data[1].include?('/opt/zimbra') 
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