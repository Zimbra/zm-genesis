#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2010 VMWare

#
# Check Zimbra doc ownership and permissions.
#
# checkme
if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end
require "action/command"
require "action/block"
require "action/verify"
require "action/runcommand"
require "model"
require "action/buildparser"

quote = '"'
if($0 == __FILE__)
  quote = '\\' + quote
end

include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Check Zimbra doc ownership and permissions "
printOption = '-exec stat'
if(Model::TARGETHOST.architecture == 1 ||
   Model::TARGETHOST.architecture == 9 ||
   Model::TARGETHOST.architecture == 39)
  printOption += ' -f '
else
  printOption += ' -c '
end
printOption += quote + '%N user:%U,group:%G,permissions:%A' + quote + ' {} \;'
file = ""

#
# Setup
#
current.setup = [
]
#
# Execution
#
current.action = [

  v(cb("/opt/zimbra/docs Permission Check") do
    mObject = Action::RunCommand.new('ls','root', '-ld', File::join(File::SEPARATOR, 'opt', 'zimbra', 'docs')).run
    mObject
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 &&
                   data[1][/#{Regexp.new("drwxr-xr-x.*(\s+#{Command::ZIMBRAUSER}){2}.*/opt/zimbra/docs")}/]
  end,

  v(RunCommand.new('ls', 'root', '-1', '/opt/zimbra/docs')) do |mcaller, data|
    if BuildParser.instance.baseBuildId =~ /NETWORK/i       
      mcaller.pass = data[0] == 0 && (files = data[1].split(/\n/)).size == 90 && files.include?("hsm-soap-admin.txt")
    else
      mcaller.pass = data[0] == 0 && (files = data[1].split(/\n/)).size == 78 && !files.include?("hsm-soap-admin.txt")
    end
  end,

  v(cb("Docs Ownership and Permission Check Files") do
    mObject = Action::RunCommand.new('find','root', "/opt/zimbra/docs",
                                     "-user zimbra",
                                     "-group zimbra",
                                     "-type f",
                                     "! -perm 444",
                                     printOption).run
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].include?('/opt/zimbra/docs')
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
