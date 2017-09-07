  #!/usr/bin/ruby -w
#
# = voume/delete.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# ZMVolume delete test
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
current.description = "ZMVolume Delete test"

tNow = Time.now.to_i.to_s
name = 'zmvolume'+File.basename(__FILE__,'.rb')+tNow
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
volumeID = -1

current.action = [ 

  #Delete current primaryMessage not allowed
  ZMVolumeHelper.genCreateSet(mfilePath = File.join(Command::ZIMBRAPATH, testPath = "deletepositive"+tNow), 
    testPath, 'primaryMessage'),   
  ZMVolumeHelper.genSendVerify(testAccount.name, mfilePath, message.gsub(/REPLACEME/, testAccount.name).
    gsub(/MARKINDEX/, testPath)),    
  v(ZMVolumeHelper.genDeleteByName(testPath)) do |mcaller, data|  
    #The data here is actually a verify object, the result is in response
    mcaller.pass = (data.response[0] == 1) && 
      (data.response[1].include?('current volume')) 
  end,
    
  #Delete noncurrent
  ZMVolumeHelper.genCreateSet(mfilePath = File.join(Command::ZIMBRAPATH, testPath = "delenoncurrent"+tNow), 
    testPath, 'primaryMessage'),   
  ZMVolumeHelper.genReset,
  v(ZMVolumeHelper.genDeleteByName(testPath)) do |mcaller, data|  
    #The data here is actually a verify object, the result is in response
#    puts "data here"
#    puts YAML.dump(data)
#    puts data.response.first.class
#    puts "----"
    result = data.response.join               
    mcaller.pass = (result.include?('deleting volume entry') || result.include?('Deleted')) 
      if(data.response[1] =~ /volume.*?(\d+)/m)
        volumeID = $1 
      end 
  end,  
  ZMVolumeHelper.genSendVerify(testAccount.name, File.join(Command::ZIMBRAPATH,'store'), 
    message.gsub(/REPLACEME/, testAccount.name).gsub(/MARKINDEX/, "shouldbebacktoanotherone")),    
  
  #Delete something doesn't exist
  ['9999999', '-2'].map do |x|
    v(ZMVolume.new('-d', '-id', x), &ZMVolumeHelper.Error("Error occurred"))
  end, 
  
  #Delete recent deleted  
  v(cb("Delay Check") {
      ZMVolume.new('-d', '-id', volumeID).run}) do |mcaller, data|
                    result = data.join 
                    mcaller.pass = 
                      (data[0] == 1) && ['deleteing volume entry', 'Delete', 'no such volume'].any? do |ww|
                      result.include?(ww)
                    end
                    mcaller.message = "Fail check delay check" unless mcaller.pass 
  end,
  
  #Error in arguments  
  ['','-id'].map do |x|
    v(ZMVolume.new('-d', '-id', x), &ZMVolumeHelper.Error('Error parsing'))
  end, 
  
  ['a','2+3'].map do |x|
    v(ZMVolume.new('-d', '-id', x), &ZMVolumeHelper.Error("Error occurred: For input string"))
  end,  
 
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
