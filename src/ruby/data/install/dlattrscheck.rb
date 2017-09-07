#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2011 Vmware
#
# Check zimbradladmins, zimbradomainadmins DLs attributes
 

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "model"
require "action/zmprov"
require "action/block"
require "action/verify"


#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Check Default DL attributes"


include Action

mDom = ZMProv.new('gcf', 'zimbraDefaultDomainName').run[1].split.last
zimbradladmins =  Model::User.new('zimbradladmins@' + mDom, Model::DEFAULTPASSWORD)
zimbradomainadmins =  Model::User.new('zimbradomainadmins@' + mDom, Model::DEFAULTPASSWORD)

#
# Setup
#
current.setup = [ ]

#
# Execution
#
current.action = [  
  v(ZMProv.new('gdl', zimbradladmins.name)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && 
                   data[1] =~ /zimbraHideInGal:\s+TRUE/ &&
                   data[1] =~ /zimbraMailStatus:\s+disabled/ &&
                   data[1] =~ /zimbraAdminConsoleUIComponents:\s+DLListView/
  end,
  
  v(ZMProv.new('gdl', zimbradomainadmins.name)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && 
                   data[1] =~ /zimbraHideInGal:\s+TRUE/ &&
                   data[1] =~ /zimbraMailStatus:\s+disabled/ &&
                   data[1].split(/\n/).select{|w| w =~ /zimbraAdminConsoleUIComponents:/}.collect{|w| w.split.last}.sort == ['accountListView', 'aliasListView', 'DLListView', 'resourceListView', 'saveSearch'].sort
  end,
  
  v(ZMProv.new('gadl')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1] !~ /zimbraoctopus/
  end,

]
#
# Tear Down
#
current.teardown = [ ]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance
  Engine::Simple.new(Model::TestCase.instance).run
end

