#!/usr/bin/ruby -w
#
# = voume/list.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# ZMVolume list test
# 

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"
require "action/block"
require "action/command" 
require "action/zmvolume"
require "action/zmprov" 
require "action/verify"
require "net/imap"; require "action/imap" #Patch Net::IMAP library

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "ZMVolume List test"

 
 
include Action
 
#
# Setup
#
current.setup = [
  
] 
 
 
#
# Execution
#
volumeID = -1

current.action = [ 
  #List General
  v(ZMVolume.new('-l')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && 
      data[1].include?(File.join(Command::ZIMBRAPATH, 'store')) &&
      data[1].include?(File.join(Command::ZIMBRAPATH, 'index'))
    mcaller.message = "Can not find zimbra store or zimbra index" unless mcaller.pass
  end,
  
  #List something doesn't exist
  v(ZMVolume.new('-l','-id','500'), &ZMVolumeHelper.Error("Error occurred: no such volume")),  
  v(ZMVolume.new('-l','-id','-2'), &ZMVolumeHelper.Error("Error occurred: no such volume")),  
  
  #List By ID
  v(ZMVolume.new('-l', '-id', '1')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && 
      data[1].include?(File.join(Command::ZIMBRAPATH, 'store')) 
  end,
  
  #Error in arguments  
  ['','-id'].map do |x|
    v(ZMVolume.new('-l', '-id', x), &ZMVolumeHelper.Error('Error parsing'))
  end,
  
   
  ['a', '2+3'].map do |x|
    v(ZMVolume.new('-l', '-id', x), &ZMVolumeHelper.Error("Error occurred: For input string"))
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