#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2011 VMWare, Inc.
#
# check network related subs 

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"  
require "action/runcommand"
require "action/verify"
require "action/block"
require "action/zmlicense"
require "action/zmprov"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Network install script check"

include Action 

currentUsers = -2
 
#
# Setup
#
current.setup = [
   
]

#
# Execution
#
current.action = [  
  RunCommand.new('/bin/cp', 'root', File.join(Command::ZIMBRAPATH, 'conf', 'ZCSLicense.xml'),
                 File.join(Command::ZIMBRAPATH, 'conf', 'ZCSLicense.xml.sav')),
  v(cb("License limit check", 300) do
    mResult = ZMProv.new('-l', 'cto', 'userAccounts').run
    next mResult if mResult[0] != 0
    currentUsers = mResult[1].split(/\n/).first.to_i
    #TODO: set license type based on the existing license
    licenseType = 'regular'
    res = []
    #[-1, mCount - 1, mCount, mCount + 1].each do |licenseLimit|
    [currentUsers + 1].each do |licenseLimit|
      #install temp license
      prefix = "ZQA" + (licenseLimit == -1 ? "Unlimited" : licenseLimit.to_s)
      mResult = RunCommand.new('/bin/env',Command::ZIMBRAUSER,'wget', '--no-proxy',
                                '-O', File.join(Command::ZIMBRAPATH, 'conf', "#{prefix}UsersLicense.xml"),
                                "http://zimbra-stage-license-vip.vmware.com/zimbraLicensePortal/QA/LKManager --post-data=\"AccountsLimit=#{licenseLimit}&ArchivingAccountsLimit=#{licenseLimit}&InstallType=#{licenseType}\"").run
      next mResult if mResult[0] != 0
      mResult = ZMLicense.new('-i', File.join(Command::ZIMBRAPATH, 'conf', "#{prefix}UsersLicense.xml")).run
      next mResult if mResult[0] != 0
      mResult = RunCommand.new('/bin/cp', 'root',
                               File.join(Command::ZIMBRAPATH, 'conf', "#{prefix}UsersLicense.xml"),
                               File.join(Command::ZIMBRAPATH, 'conf', "ZCSLicense.xml")).run
      mResult = ZMLicense.new('-a').run
      next mResult if mResult[0] != 0
      mResult= RunCommand.new('zmcontrol', Command::ZIMBRAUSER, 'stop').run
      mResult = RunCommand.new('cd', 'root', File.join(Command::ZIMBRAPATH, '.uninstall'),
                               '; echo -e "N\nY" | ./install.sh -s --beta-support -x').run
      res = mResult
      mResult= RunCommand.new('zmcontrol', Command::ZIMBRAUSER, 'start').run
    end
    res
  end) do |mcaller, data|
    mcaller.pass = data[1].split(/\n/).select {|w| w =~ /\.\/util\/utilfunc\.sh: line \d+/}.empty?
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'License limit check' => {"IS" => data[1] + ", exitCode=#{data[0]}", "SB" => (data[2] or "Success")}}
    end
  end,
  
  RunCommand.new('/bin/cp', 'root', File.join(Command::ZIMBRAPATH, 'conf', 'ZCSLicense.xml.sav'),
                 File.join(Command::ZIMBRAPATH, 'conf', 'ZCSLicense.xml')),
  
  v(ZMLicense.new('-i', '/opt/zimbra/conf/ZCSLicense.xml')) do |mcaller, data|
    mcaller.pass = (data[0] == 0)
  end,
  
  v(ZMLicense.new('-a')) do |mcaller, data|
    mcaller.pass = (data[0] == 0)
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