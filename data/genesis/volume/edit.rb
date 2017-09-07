#!/bin/env ruby
#
# = voume/edit.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# ZMVolume edit test
# 

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"
require "action/block"
require "action/command"
require "action/clean"
require "action/zmvolume"
require "action/zmprov" 
require "action/verify"
require "net/imap"; require "action/imap" #Patch Net::IMAP library

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "ZMVolume Edit test"

nNow = Time.now.to_i.to_s
name = File.expand_path(__FILE__).sub(/.*?(data\/)(genesis\/)?(zm)?/, 'zm').sub('.rb', '').gsub(/\/|\(|\)/, '') + nNow
#name = "admin" if ($0 == __FILE__)
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)
 
include Action
 
#
# Setup
#
current.setup = [
  Action::RunCommand.new(File.join(Command::ZIMBRAPATH, 'postfix', 'sbin', 'postsuper'), 'root', '-d ALL'),
  if Action::RunCommand.new('ls', 'root', '-R', '-l', File.join(Command::ZIMBRAPATH,"store", "incoming")).run[1].split(/\n/).select { |mdata| mdata.include?('.msg')}.size != 0
  [
     Clean.new(File.join(Command::ZIMBRAPATH,"store", "incoming"))
  ]  end,
  CreateAccount.new(testAccount.name,testAccount.password)
]

message = <<EOF.gsub(/\n/, "\r\n")
Subject: hello
From: genesis@test.org
To: REPLACEME

This message is for MARKINDEX
EOF

 
#
# Execution
#
volumeID = -1

current.action = [ 
  #Edit current primary volume, change everything
  ZMVolumeHelper.genCreateSet(mfilePath = File.join(Command::ZIMBRAPATH, testPath = "editcurchangename" + nNow), 
    testPath, 'primaryMessage'),     
  mid = ZMVolumeHelper.genGetIdByName(testPath), 
  [
    ['Edit current primary name', ['-n', 'kid' + nNow], 'kid' + nNow],
    ['Edit current primary compress true', ['-c', 'true'], 'compressed: true'],
    ['Edit current primary compress true', ['-ct', '1'], '1 bytes'],
    ['Edit current primary compress false', ['-c', 'false'], 'compressed: false'],
  ].map do |x|
    [ZMVolumeHelper.genEditVerify(x[0], mid, x[1], x[2]),
      ZMVolumeHelper.genSendVerify(testAccount.name, mfilePath, message.gsub(/REPLACEME/, testAccount.name).
      gsub(/MARKINDEX/, testPath+YAML.dump(x))), 
    ]
  end,
  
  #Should not able to change from current primary to anything else
  [
    ['Edit current primary to index', ['-t', 'index'], 'primaryMessage'],
    ['Edit current primary to secondary', ['-t', 'secondaryMessage'], 'primaryMessage'],
    ['Edit current primary to primary', ['-t', 'primaryMessage'], 'primaryMessage'],
  ].map do |x|
    [ZMVolumeHelper.genEditVerify(x[0], mid, x[1], x[2]),
      ZMVolumeHelper.genSendVerify(testAccount.name, mfilePath, message.gsub(/REPLACEME/, testAccount.name).
      gsub(/MARKINDEX/, testPath+YAML.dump(x))), 
    ]
  end,
  
  #Edit current secondary volume
  ZMVolumeHelper.genCreateSet(sfilePath = File.join(Command::ZIMBRAPATH, stestPath = "editcurchangesecondary" + nNow), 
    stestPath, 'secondaryMessage'),     
  msid = ZMVolumeHelper.genGetIdByName(stestPath), 
  [
    ['Edit current secondary name', ['-n', 'kidsecondary' + nNow], 'kidsecondary' + nNow],
    ['Edit current secondary compress true', ['-c', 'true'], 'compressed: true'],
    ['Edit current secondary compress true', ['-ct', '1'], '1 bytes'],
    ['Edit current secondary compress false', ['-c', 'false'], 'compressed: false'],
  ].map do |x|
    [ZMVolumeHelper.genEditVerify(x[0], msid, x[1], x[2]),
      ZMVolumeHelper.genSendVerify(testAccount.name, mfilePath, message.gsub(/REPLACEME/, testAccount.name).
      gsub(/MARKINDEX/, testPath+YAML.dump(x))), 
    ]
  end,
  
  #Should not able to change from current secondary to anything else
  [
    ['Edit current secondary to index', ['-t', 'index'], 'secondaryMessage'],
    ['Edit current secondary to secondary', ['-t', 'primaryMessage'], 'secondaryMessage'],
    ['Edit current secondary to primary', ['-t', 'secondaryMessage'], 'secondaryMessage'],
  ].map do |x|
    [ZMVolumeHelper.genEditVerify(x[0], msid, x[1], x[2]),
      ZMVolumeHelper.genSendVerify(testAccount.name, mfilePath, message.gsub(/REPLACEME/, testAccount.name).
      gsub(/MARKINDEX/, testPath+YAML.dump(x))), 
    ]
  end,  
  
  #Edit inactive volume
  ZMVolumeHelper.genReset,
  [
    ['Edit current inactive name', ['-n', 'kidinactive' + nNow], 'kidinactive' + nNow],
    ['Edit current inactive compress true', ['-c', 'true'], 'compressed: true'],
    ['Edit current inactive compress true', ['-ct', '1'], '1 bytes'],
    ['Edit current inactive compress false', ['-c', 'false'], 'compressed: false'],
    ['Edit current inactive to index', ['-t', 'index'], 'index'],
    ['Edit current inactive to secondary', ['-t', 'secondaryMessage'], 'secondaryMessage'],
    ['Edit current inactive to primary', ['-t', 'primaryMessage'], 'primaryMessage'],
  ].map do |x|
    [ZMVolumeHelper.genEditVerify(x[0], mid, x[1], x[2]),
      ZMVolumeHelper.genSendVerify(testAccount.name, File.join(Command::ZIMBRAPATH,'store'), message.gsub(/REPLACEME/, testAccount.name).
      gsub(/MARKINDEX/, testPath+YAML.dump(x))), 
    ]
  end,   
]

#
# Tear Down
#
current.teardown = [         
  #DeleteAccount.new(testAccount.name)
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end