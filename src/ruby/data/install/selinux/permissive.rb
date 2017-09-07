#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2012 VMWare, Inc.
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
require "action/runcommand"
#require "action/zmprov"
require "action/verify"
#require "action/zmamavisd"
#require "action/zmproxyconfig"
#require "#{mypath}/install/configparser"
#require "#{mypath}/install/utils"
#require 'rexml/document'
#include REXML

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "permissive selinux"

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

  v(cb("selinux permissive setup") do
    mResult = RunCommand.new('getenforce', 'root').run
    next mResult if mResult[0] != 0
    #mData = /testlogs#{File::SEPARATOR}([^#{File::SEPARATOR}]+)#{File::SEPARATOR}([^#{File::SEPARATOR}]+)#{File::SEPARATOR}/.match(@logdest)
    #os = mData[1] if !mData.nil?
    #next [1, @logdest] if mData.nil?
    mResult = RunCommand.new('cat', 'root', File.join([File::SEPARATOR, 'etc', 'selinux', 'config'])).run
    next mResult if mResult[0] != 0
    next mResult if mResult[1] =~ /\nSELINUX=permissive\s*\n/
    mResult = RunCommand.new('sed', 'root', '-i.bak', "s/^SELINUX=.*/SELINUX=permissive/",
                             File.join([File::SEPARATOR, 'etc', 'selinux', 'config'])).run

  end) do |mcaller, data|
    mcaller.pass = data[0] == 0
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