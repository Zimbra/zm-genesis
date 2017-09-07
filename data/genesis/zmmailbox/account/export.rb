#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2011 VMWare
#
# zmmailbox export test

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"
require "action/block"
require "action/zmmailbox"
require "action/zmprov"
require "action/verify"
require "action/zmlmtpinject"
require "action/waitqueue"


#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "zmmailbox account export test"

 
include Action

name = 'zmmailbox'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s  
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)
adminAccount = Model::TARGETHOST.cUser('admin', Model::DEFAULTPASSWORD)
mFile = File.join(Command::ZIMBRAPATH, 'data', 'tmp', 'msg01.txt')
 
#
# Setup
#
current.setup = [
 
]

#
# Execution
#
current.action = [
  CreateAccount.new(testAccount.name,testAccount.password),
  
  #create a conversation
  cb("Create message file") do
    rawMessage = IO.readlines(File.join(Model::DATAPATH, 'email01', 'msg01.txt'))
    message = rawMessage.collect do |w|
                w.gsub(/To: \S+/, "To: #{testAccount.name}")
              end.collect do |w|
                w.gsub(/Subject: \S+/, "Subject: #{testAccount.name}")
              end.collect do |w|
                w.gsub(/From: \S+/, 'From: genesis@zimbratest.com')
              end
    File.open(mFile, "w") do |file|
      file.puts message.join('')
    end
  end,
  
  ZMLmtpinject.new('-r', testAccount.name, '-s', 'genesis@zimbratest.com', mFile),
  
  cb("Create message reply file") do
    rawMessage = IO.readlines(File.join(Model::DATAPATH, 'email01', 'msg01.txt'))
    message = rawMessage.collect {|w| w.gsub(/Subject: \S+/, "Subject: Re: #{testAccount.name}")}
    File.open(mFile, "w") do |file|
      file.puts message.join('')
    end
  end,
  
  ZMLmtpinject.new('-r', testAccount.name, '-s', 'genesis@zimbratest.com', mFile),
  
  Action::WaitQueue.new,
  
  #export: zmmailbox -z -m testAccount.name getRestURL "//?fmt=tgz" > mfile.tgz
  v(RunCommand.new(File.join(Command::ZIMBRAPATH, 'bin', 'zmmailbox'), Command::ZIMBRAUSER, '-z',
                   '-m', testAccount.name, 'getRestURL', "\"//?fmt=tgz\"", '>',
                   tFile = File.join(Command::ZIMBRAPATH, 'data', 'tmp', name + '.tgz'))) do |mcaller, data|  
    mcaller.pass = data[0] == 0       
  end, 
  
  v(RunCommand.new('tar', 'root', 'tzf', tFile)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1] !~ /Conversations\/\S+\.meta/
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'Conversations test' => {"SB" => 'No such file(s)',
                                                  "IS" => data[1].split(/\n/).select {|w| w =~ /Conversations\/\S+\.meta/}.join(' ')}}
    end
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