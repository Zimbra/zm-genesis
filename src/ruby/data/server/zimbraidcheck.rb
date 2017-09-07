#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2012 VMWare
#
# check for unique zimbraId

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

mypath = 'data'
if($0 =~ /data\/genesis/)
  mypath += '/genesis'
end

require "model"
require "action/block"
require "action/verify"
require "action/runcommand"
require "#{mypath}/install/configparser"
require 'action/zmslapcat'
require 'tmpdir'

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "zimbraId uniqueness test"


include Action

mName = File.expand_path(__FILE__).sub(/.*?(data\/)(genesis\/)?(zm)?/, 'zm').sub('.rb', '').gsub(/\/|\(|\)/, '') + Time.now.to_i.to_s
mDir = File.join(Command::ZIMBRAPATH, 'data', 'tmp', mName)

#
# Setup
#
current.setup = [

]

#
# Execution
#
current.action = [
  
  v(cb("zimbraId check") do
    (mCfg = ConfigParser.new()).run
    mHost = mCfg.getServersRunning('ldap').first
    mResult = ZMSlapcat.new(mDir, h = Model::Host.new(mHost)).run
    RunCommand.new('grep', Command::ZIMBRAUSER, 'zimbraId: ', File.join(mDir, 'ldap.bak'), h).run
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && (res = data[1].gsub(/zimbraId:\s+/, '').split(/\n/)).size == res.uniq.size
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mDup = res.inject(Hash.new(0)) {|h,v| h[v] += 1; h}.reject{|k,v| v==1}.keys
      mcaller.badones = {'zimbraId test' => {"SB" =>"unique", "IS" => "duplicate ids: #{mDup.join(", ")}"}}
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
