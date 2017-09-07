#!/bin/env ruby
#
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2006 Zimbra
#
# Documented by Bill Hwang
#
# ZMVolume add negative test
# 

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"
require "action/block"
require "action/command"

require "action/sendmail" 
require "action/zmvolume"
require "action/zmprov"
require "action/proxy"
require "action/verify"
require "net/imap"; require "action/imap" #Patch Net::IMAP library

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "ZMVolume Add Negative test"

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

message = <<EOF.gsub(/\n/, "\r\n")
Subject: hello
From: genesis@test.org
To: REPLACEME

This message is for MARKINDEX
EOF

 
#
# Execution
# 
mfilePath = File.join(Command::ZIMBRAPATH, "addnegativerelative")  

current.action = [
  #Relative Path
  ZMVolumeHelper.genCreateSet(mfilePath, 'addnegativerelative', 'primaryMessage', '/opt/zimbra/../zimbra/addnegativerelative'), 
  ZMVolumeHelper.genSendVerify(testAccount.name, mfilePath, message.gsub(/REPLACEME/, testAccount.name).
    gsub(/MARKINDEX/,"addnegativerelative")),
  ZMVolumeHelper.genReset,  
   
  # Point to the existing path
  Verify.new(ZMVolume.new('-a','-n', 'collision' , '-t', 'primaryMessage', '-p', 
    File.join(Command::ZIMBRAPATH, 'store')), &ZMVolumeHelper.Error('already exists')),
 
  # Point to missing file path
  Verify.new(ZMVolume.new('-a','-n', 'collision' , '-t', 'primaryMessage', '-p', 
    File.join(Command::ZIMBRAPATH, 'notstore')), &ZMVolumeHelper.Error('does not exist')),
  
  #Nested
  Verify.new(ZMVolume.new('-a','-n', 'collision' , '-t', 'primaryMessage', '-p', 
    File.join(mfilePath,'incoming')), &ZMVolumeHelper.Error('subdirectory')), 
  
  # . and ..
  Verify.new(ZMVolume.new('-a','-n', 'currentdot' , '-t', 'primaryMessage', '-p', 
    '.'), &ZMVolumeHelper.Error('is not an absolute path')), 
    
  Verify.new(ZMVolume.new('-a','-n', 'currentdotdot' , '-t', 'primaryMessage', '-p', 
    '..'), &ZMVolumeHelper.Error('is not an absolute path')), 
 
  # Use the same name
  Verify.new(ZMVolume.new('-a','-n', 'addnegativerelative' , '-t', 'primaryMessage', '-p', '/bin'),
    &ZMVolumeHelper.Error('not writable')), 

   # Missing switches
   [
    ['-a', '-t', 'primaryMessage', '-p', '/bin'],
    ['-a', '-n', 'hi', '-p', '/bin'],
    ['-a', '-n', 'hi', '-t', 'primaryMessage'],
   ].map do |x|
     Verify.new(ZMVolume.new(*x), &ZMVolumeHelper.Error('missing'))
   end,
   
  # Double switches
  Verify.new(ZMVolume.new('-a','-n','double','-t', 'index', 
    '-t', 'primaryMessage', '-p', '/tmp')) do |mcaller, data|
      mcaller.pass = (data[0] == 0) && (data[1].include?('created'))
  end,
  
  Verify.new(ZMVolume.new('-a','-n', 'addgarbage' , '-t', 'primaryMessage', '-p', '/tmp',
    '-c', 'true', '-ct', '-1')) do |mcaller, data|
      mcaller.pass = data[0] == 1 && data[1].include?('Error occurred: invalid request: compressionThreshold cannot be a negative number')
  end,

  Verify.new(ZMVolume.new('-a','-n', 'addgarbage' , '-t', 'primaryMessage', '-p', '/tmp',
    '-c', 'true', '-ct', 'a')) do |mcaller, data|
      mcaller.pass = data[0] == 1 && data[1].include?('Error occurred: For input string')
  end,

    
   # Some threshold test
   ['0', '23', '1','10000000'].map do |x|
    nfilePath = File.join(Command::ZIMBRAPATH, "compress#{x}")
    nName = "compress#{x}"
    [
      ZMVolumeHelper.genCreateSet(nfilePath, nName, 'primaryMessage', nfilePath, 
        ZMVolume.new('-a', '-n', nName, '-t', 'primaryMessage', '-c', 'true', 
          '-p', nfilePath, '-ct', "#{x}")
      ), 
      ZMVolumeHelper.genSendVerify(testAccount.name, nfilePath, message.gsub(/REPLACEME/, testAccount.name).
        gsub(/MARKINDEX/,nName)),
      ZMVolumeHelper.genReset, 
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