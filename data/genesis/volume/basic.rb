#!/usr/bin/ruby -w
#
# = volume/basic.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# ZMVolume basic test
# 

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"
require "action/block"
require "action/zmvolume"
require "action/zmprov"
require "action/proxy"
require "action/verify"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "ZMVolume Basic test"

name = 'zmvolume'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
name = "admin" if ($0 == __FILE__)
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)
 
include Action
 
#
# Setup
#
current.setup = [
   CreateAccount.new(testAccount.name,testAccount.password) 
]

#
# Execution
#
current.action = [
  v(ZMVolume.new) do |mcaller, data| 
    mcaller.pass = (data[0] == 1) && data[1].include?('zmvolume') &&
      data[1].include?('Error')
  end,
  
  ['-e','--edit','-d', '--delete', '-sc', '--setCurrent'].map do |x|
    v(ZMVolume.new(x)) do |mcaller, data| 
      mcaller.pass = (data[0] == 1) && data[1].include?('zmvolume') &&
        data[1].include?('Error') 
    end
  end,
  
  ['-a','--add','-add'].map do |x|
    v(ZMVolume.new(x)) do |mcaller, data|  
      mcaller.pass = (data[0] == 1) &&
        data[1].include?('type is missing') 
    end
  end,
  
  ['-l', '--list', '-dc', '--displayCurrent'].map do |x|
    v(ZMVolume.new(x)) do |mcaller, data|
      mcaller.pass = (data[0] == 0) &&
        data[1].include?('/opt/zimbra/store') &&
        data[1] =~ %r(/opt/zimbra/index) 
    end
  end, 
  
  ['-x', '--x'].map do |x|
    v(ZMVolume.new(x)) do |mcaller, data|
      mcaller.pass = (data[0] == 1) &&
        data[1].include?('zmvolume') &&
        data[1].include?('Unrecognized option')
    end
  end,
  
  ['-ts', '--turnOffSecondary'].map do |x|
    v(ZMVolume.new(x)) do |mcaller, data|
      mcaller.pass = (data[0] == 0) &&
        data[1].include?('Turned off the current secondary message volume')
    end
  end  
 
]

#
# Tear Down
#
current.teardown = [        
  DeleteAccount.new(testAccount.name)
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end
