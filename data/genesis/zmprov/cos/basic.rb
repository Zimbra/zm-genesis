#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2006 Zimbra
#
# zmprov cos basic test

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
current.description = "Zmprov Cos Basic test"


include Action

name = 'zmprov'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
cosname1 = 'cos'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
#
# Setup
#
current.setup = [

]

#
# Execution
#
current.action = [  
  #Create COS
  v(ZMProv.new('cc','zmprovtestcos')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,

  #Get All COS
  v(ZMProv.new('gac')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('zmprovtestcos')
  end,

  #Get COS
  v(ZMProv.new('gc', 'default')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('cn: default')
  end,

  #Modify COS
  v(ZMProv.new('mc', 'zmprovtestcos', 'cn', 'zmprovtestcos')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,

  #Rename COS
  v(ZMProv.new('rc', 'zmprovtestcos', 'zmprovtestcos1')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,

  v(ZMProv.new('gc', 'zmprovtestcos')) do |mcaller, data|
    mcaller.pass = data[0] == 2 && data[1].include?('ERROR: account.NO_SUCH_COS (no such cos: zmprovtestcos)')
  end,

  v(ZMProv.new('gc', 'zmprovtestcos1')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?("zimbraJunkMessagesIndexingEnabled: TRUE")
  end,

  # Copy COS
  v(ZMProv.new('cpc', 'zmprovtestcos1','zmprovtestcos')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,

  #Delete COS
  v(ZMProv.new('dc','zmprovtestcos')) do |mcaller, data|  
    mcaller.pass = data[0] == 0  
  end,  

  v(ZMProv.new('dc','zmprovtestcos1')) do |mcaller, data| 
    mcaller.pass = data[0] == 0  
  end,

  # Test : Check that dumpster is disabled by default and perform operations to enable and disable it.
  
  v(ZMProv.new('gc','default','zimbraDumpsterEnabled')) do |mcaller, data| 
    mcaller.pass = data[0] == 0 && data[1].include?('zimbraDumpsterEnabled: FALSE')
  end,
  
  v(ZMProv.new('cc',cosname1)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,

  v(ZMProv.new('mc',cosname1,'zimbraDumpsterEnabled','TRUE')) do |mcaller, data| 
    mcaller.pass = data[0] == 0
  end,

  v(ZMProv.new('gc',cosname1,'zimbraDumpsterEnabled')) do |mcaller, data| 
    mcaller.pass = data[0] == 0 && data[1].include?('zimbraDumpsterEnabled: TRUE')
  end,

  v(ZMProv.new('mc',cosname1,'zimbraDumpsterEnabled','FALSE')) do |mcaller, data| 
    mcaller.pass = data[0] == 0
  end,

  v(ZMProv.new('gc',cosname1,'zimbraDumpsterEnabled')) do |mcaller, data| 
    mcaller.pass = data[0] == 0 && data[1].include?('zimbraDumpsterEnabled: FALSE')
  end,

  # End Test
   
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