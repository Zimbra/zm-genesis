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
require "action/zmprov"
require "action/verify"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Server Imap Cache directory check"


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
  v(cb("ls on cache directory") do
      RunCommand.new('ls', 'root', File.join(Command::ZIMBRAPATH, 'data', 'mailboxd', 'imap')).run
  end) do |mcaller, data|
    mcaller.pass = data[1].include?("No such file or directory")
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
