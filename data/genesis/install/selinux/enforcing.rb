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
require "action/verify"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "enforce selinux on 8.0+ builds"

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

  v(cb("selinux enforcing") do
    mResult = RunCommand.new('getenforce', 'root').run
    next mResult if mResult[0] != 0
    #mData = /testlogs#{File::SEPARATOR}([^#{File::SEPARATOR}]+)#{File::SEPARATOR}([^#{File::SEPARATOR}]+)#{File::SEPARATOR}/.match(@logdest)
    #os = mData[1] if !mData.nil?
    #next [1, @logdest] if mData.nil?
    mResult = RunCommand.new('cat', 'root', File.join([File::SEPARATOR, 'etc', 'selinux', 'config'])).run
    next mResult if mResult[0] != 0
    if mResult[1] !~ /\nSELINUX=permissive\s*\n/
      mResult = RunCommand.new('sed', 'root', '-i.bak', "s/^SELINUX=.*/SELINUX=permissive/",
                               File.join([File::SEPARATOR, 'etc', 'selinux', 'config'])).run
      next mResult if mResult[0] != 0
    end
    RunCommand.new('setenforce', 'root', 'enforcing').run
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  
  if RunCommand.new('getenforce', 'root').run[0] == 0
  [
    if !(mData = /testlogs#{File::SEPARATOR}([^#{File::SEPARATOR}]+)#{File::SEPARATOR}([^#{File::SEPARATOR}]+)#{File::SEPARATOR}/.match(@logdest)).nil? &&
       mData[1] =~ /RHEL6/
    [
      # 'ssh-keygen' not needed in R6.3 
      ['ifconfig', 'hostname', 'ip'].map do |x|
        v(cb("adjust RHEL6 context") do
          RunCommand.new('chcon', 'root', '-t', 'bin_t', "`which #{x}`").run
        end) do |mcaller, data|
          mcaller.pass = data[0] == 0
        end
      end
    ]
    end
  ]
  end,
  
  if RunCommand.new('getenforce', 'root').run[0] == 0
  [ 
    if !(mData = /testlogs#{File::SEPARATOR}([^#{File::SEPARATOR}]+)#{File::SEPARATOR}([^#{File::SEPARATOR}]+)#{File::SEPARATOR}/.match(@logdest)).nil? &&
       mData[1] =~ /UBUNTU/
    [
      ['hostname', 'ssh-keygen', 'cron', 'crontab'].map do |x|
        v(cb("adjust UBUNTU context") do
          RunCommand.new('chcon', 'root', '-t', 'bin_t', "`which #{x}`").run
        end) do |mcaller, data|
          mcaller.pass = data[0] == 0
        end
      end,

      # workaround for ssh login
      v(RunCommand.new('service', 'root', 'ssh', 'stop', ';/usr/sbin/sshd', '-D', '2>&1&')) do |mcaller, data|
        mcaller.pass = data[0] == 0
      end
    ]
    end 
  ]
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