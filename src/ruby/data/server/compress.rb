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

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 

mypath = 'data'
if($0 =~ /data\/genesis/)
  mypath += '/genesis'
end

require "model" 
require "action/runcommand" 
require "action/verify"
require "#{mypath}/install/utils"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Server Compress fetch test"

include Action

mUri = Utils::getClientURIInfo
 
#
# Setup
#
current.setup = [] 
#
# Execution
#

current.action = [       

  # Get a list of executables   
  v(RunCommand.new('wget','root', '--no-proxy', '--no-check-certificate', '-t', '2', '-O',  File.join('/tmp', 'compressed.gz'), 
                   "\"#{mUri[:mode]}://#{mUri[:target]}:#{mUri[:port]}/js/skin.js?client=advanced&compress=true\"")
    ) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,  
  RunCommand.new('rm', 'root', '-f', File.join('/tmp', 'compressed.gz')),                  
 ]

#
# Tear Down
#
current.teardown = []

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end 
