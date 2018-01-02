#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2010 VMWare
#
# zmprov config basic test

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model" 
require "action/zmprov" 
require "action/verify"


#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Zmprov Config Basic test"

 
include Action

name = 'zmprov'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s  
 
#
# Setup
#
current.setup = [
   
]

#
# Execution
#
current.action = [     
  #Get All Config
  v(ZMProv.new('gacf')) do |mcaller, data|	
    mcaller.pass = data[0] == 0 && data[1].include?('zimbraAdminPort:') 
  end,

  v(ZMProv.new('getAllConfig')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('zimbraImapServerEnabled') 
  end,
  #Get Config
  v(ZMProv.new('gcf', 'zimbraImapServerEnabled')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && ['TRUE', 'FALSE'].any? do |x|
      data[1].include?(x)
    end 
  end,

  #Modify Config
  v(ZMProv.new('mcf', 'holder', 'whatever')) do |mcaller, data|
    mcaller.pass = data[1].include?('INVALID_ATTR_NAME')
  end, 

  #Adding Verification tests for bug 9439
  v(ZMProv.new('gcf', 'zimbraVersIonChEckSendNotificationS')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && ['TRUE', 'FALSE'].any? do |x|
      data[1].include?(x)
    end
  end,

  v(ZMProv.new('gcf', 'zimbradefaultdomainname')) do |mcaller, data|
    mcaller.pass = 0 && data[1].include?(Model::TARGETHOST)
  end,

  #bug 61278
  v(ZMProv.new('gcf', 'zimbraMtaMaxMessageSize ')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?("10240000")
  end,

  v(ZMProv.new('mcf', 'zimbraMtaMaxMessageSize', '10737419264')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && (data[1].nil? || data[1].include?(" ") || data[1].include?(""))
  end,

  v(ZMProv.new('mcf', 'zimbraMtaMaxMessageSize', '10240000')) do |mcaller, data|
    mcaller.pass = data[0] == 0 
  end,

  #Bug 85183
  
  v(ZMProv.new('mcf', 'zimbraHttpThrottleSafeIPs', '111.222.11.222/32')) do |mcaller, data|
    mcaller.pass = data[0]==0 
  end, 
  
  v(ZMControl.new('restart'))do | mcaller,data|
   mcaller.pass = data[0] == 0 && !data[1].include?('failed')
  end,
    
  v(ZMProv.new('gcf', 'zimbraHttpThrottleSafeIPs')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?("111.222.11.222/32")
  end,
  
  v( ZMProv.new('gas')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?(Model::TARGETHOST.to_s.split('.').first)
  end,
  
  v(ZMProv.new('mcf', 'zimbraHttpThrottleSafeIPs', '""')) do |mcaller, data|
    mcaller.pass = data[0]==0
  end, 
  
  v(ZMControl.new('restart'))do | mcaller,data|
    mcaller.pass = data[0] == 0 && !data[1].include?('failed')
  end,
    
  v(ZMProv.new('gcf', 'zimbraHttpThrottleSafeIPs')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?("")
  end,
  
  v( ZMProv.new('gas')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?(Model::TARGETHOST.to_s.split('.').first)
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
  Engine::Simple.new(Model::TestCase.instance, true).run  
end