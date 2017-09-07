#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
#
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
require "action/verify"
require "action/buildparser"
require "action/zmlocalconfig"
require 'action/oslicense'
require "#{mypath}/install/configparser"
require "action/buildparser"


#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "libtool run path test"

include Action

#expected = Regexp.new(".*/opt/zimbra/common/lib/libltdl\..*")
#extension = '.so.7'
#cmd = 'ldd'

(mCfg = ConfigParser.new).run
mArchitecture = BuildParser.instance.targetBuildId[/zcs_([^_]+(_64)?)_/, 1]


#
# Setup
#
current.setup = [

]
#
# Execution
#

=begin
 current.action = [
  v(cb("libtool version test") do
    master = ZMLocal.new('ldap_master_url').run[/\/\/([^:\.]+)/, 1]
    host = Model::Host.new(master, Model::TARGETHOST.domain)
    mResult = RunCommandOn.new(host, 'cat', Command::ZIMBRAUSER,
                             File.join(Command::ZIMBRACOMMON,'lib', 'libltdl.la')).run
    [mResult[0], mResult[1][/libdir='([^']+)'/, 1]]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1] =~ /\/opt\/zimbra\/common\/lib/
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'libtool version test' => {"IS"=>data[1], "SB"=>OSL::LegalApproved['libtool']}}
    end
  end,

  v(cb("libtool runpath test") do
    if BuildParser.instance.targetBuildId =~ /MACOSX/i
      extension = '.dylib'
      cmd = 'otool -L'
    end
    master = ZMLocal.new('ldap_master_url').run[/\/\/([^:\.]+)/, 1]
    host = Model::Host.new(master, Model::TARGETHOST.domain)
    mObject = RunCommandOn.new(host, cmd, Command::ZIMBRAUSER,
                               File.join(Command::ZIMBRACOMMON, 'sbin', "slapacl"))
    mResult = mObject.run[1]
    #puts mResult
    if !mResult.split(/\n/).select {|w| w =~ /\s*#{expected}\s+.*/}.empty?
      [0, mResult[/\s*#{expected}\s+.*/]]
    else
      if(mResult =~ /Data\s+:/)
        mResult = (mResult)[/Data\s+:\s+(.*?)\s*\}/m, 1]
      end
      [1, ["ldd " + File.join(Command::ZIMBRACOMMON, 'sbin', "slapacl"),
           mResult[/.*libltdl\..*$/], expected.source]]
    end
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'libtool run path test' => {data[1][0] => {"IS"=>data[1][1], "SB"=>data[1][2]}}}
    end
  end,

  ]
=end


current.action = [

mCfg.getServersRunning('*').map do |x|
[
v(cb("libtool version") do
  if mArchitecture =~ /UBUNTU/
        mObject = RunCommand.new('dpkg -s zimbra-libltdl-lib',Command::ZIMBRAUSER, Model::Host.new(x))
        result = mObject.run



  else
        mObject =  RunCommand.new('yum info zimbra-libltdl-libs',Command::ZIMBRAUSER, Model::Host.new(x))
        result = mObject.run


  end
 end) do |mcaller, data|

     result = data[1][/\s(2.2...)/]
       mResult = result.strip
      mcaller.pass = data[0] == 0 && mResult == OSL::LegalApproved['libtool']
       if(not mcaller.pass)
          class << mcaller
          attr :badones, true
          end
         mcaller.badones = {x + ' - Libtool version' => {"IS" => mResult, "SB" => OSL::LegalApproved['libtool']}}
         else
         end
        end
]
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
