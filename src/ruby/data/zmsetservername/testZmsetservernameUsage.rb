#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2011 Vmware Zimbra
#
# Test case for Bug 57232 - zmsetservername usage option is not briefed
#
#if($0 == __FILE__)
#  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
#end

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "action/command"
require "action/clean"
require "action/block"
require "action/zmprov"
require "action/verify"
require "action/runcommand"
require "model"
require "action/zmsetservername"


include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test case for Bug 57232 - zmsetservername usage option is not briefed"

test_old_server_name ="mbx2.puneqa.lab"

#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [
  
  v(ZMSetservername.new('-h')) do |mcaller,data|
    mcaller.pass = (data[0] == 0 && data[1].include?("zmsetservername [-h] [-d] [-f] [-s] [-o <oldServerName>] [-v+] -n <newServerName>")\
                                 && data[1].include?("Changes the name of the local zimbra server.")\
                                 && data[1].include?("-h | --help                                 Print this usage statement.")\
                                 && data[1].include?("-f | --force                                Force the rename, bypassing safety checks.")\
                                 && data[1].include?("-o <oldServerName> | --oldServerName <oldServerName>")\
                                 && data[1].include?("-n <newServerName> | --newServerName <newServerName>")\
                                 && data[1].include?("-d | --deletelogger                         Delete the logger database for the old server")\
                                 && data[1].include?("-s | --skipusers                            Skips modifying the user database with the new server.")\
                                 && data[1].include?("-u | --usersonly                            Only updates the user database.")\
                                 && data[1].include?("-v | --verbose:                             Set the verbosity level."))
  end,  

  v(ZMSetservername.new('--oldServerName', test_old_server_name)) do |mcaller,data|
    mcaller.pass = (data[0] == 0 && !data[1].include?("Unknown option: oldservername"))   
  end,
  
  v(ZMSetservername.new('-o', test_old_server_name)) do |mcaller,data|
    mcaller.pass = (data[0] == 0 && !data[1].include?("Unknown option"))   
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
