#!/bin/env ruby
#
# $File: //depot/zimbra/JUDASPRIEST/ZimbraQA/data/genesis/zmprov/misc/description.rb $
# $DateTime: 2016/11/21 05:19:07 $
#
# $Revision: #2 $
# $Author: rvyawahare $
#
# 2009 Yahoo
#
# Test zmcommand basic functions
#
#if($0 == __FILE__)
#  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
#end

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "action/command"
require "action/clean"
require "action/block"
require "action/zmprov"
require "action/verify"
require "action/runcommand"
#require "action/zmcommand"
require "model"


include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmcommand"

entry_type = ['account','alias','distributionList','cos','globalConfig','domain',
              'server','mimeEntry','zimletEntry','calendarResource','identity',
              'dataSource','pop3DataSource','imapDataSource','rssDataSource',
              'liveDataSource','galDataSource','signature','xmppComponent',
              'aclTarget','group','shareLocator','ucService', 'alwaysOnCluster', 'addressList', 'habGroup', 'oauth2DataSource']
object_class = ['account','cos','domain','server']


#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [

  v(ZMProv.new('desc'))do |mcaller,data|
    mcaller.pass = data[0]==0
  end,

  v(ZMProv.new('describe'))do |mcaller,data|
    mcaller.pass = data[0]==0
  end,

  v(ZMProv.new('desc','-v'))do |mcaller,data|
    mcaller.pass = data[0]==0
  end,

  v(ZMProv.new('desc','-v' ,'-ni'))do |mcaller,data|
    mcaller.pass = data[0] != 0
  end,

 v(ZMProv.new('describe', 'help'))do |mcaller,data|
   mcaller.pass = data[0] != 0 &&
   mcaller.pass = !(eType = data[1][/^Valid entry types: (.*)$/, 1]).empty? &&
                  eType.split(/\s*,\s*/).sort == entry_type.sort
  end,
  
  object_class.collect! do |x|
    v(ZMProv.new('desc',x))do |mcaller,data|
      mcaller.pass = data[0]==0
    end
  end,

  entry_type.dup.collect! do |y|
    v(ZMProv.new('desc','-ni',y))do |mcaller,data|
      mcaller.pass = data[0] == 0
    end
  end,

  entry_type.dup.collect! do |y|
    v(ZMProv.new('desc', '-ni', '-v', y))do |mcaller,data|
      mcaller.pass = data[0]==0
    end
  end,

  v(ZMProv.new('desc','-a' ,'zimbraId'))do |mcaller,data|
    mcaller.pass = data[0]==0
  end,
  
  #check description of zimbraEphemeralBackendURL.. 
  v(ZMProv.new('desc','-a' ,'zimbraEphemeralBackendURL'))do |mcaller,data|
     mcaller.pass = data[0]==0 && data[1].include?("URL of ephemeral storage backend")
  end,
  
  v(ZMProv.new('desc','domain','-a' ,'zimbraAccountStatus'))do |mcaller,data|
    mcaller.pass = data[0]==1 && data[1].include?('cannot specify -a when entry type is specified')
  end,
	
	#Attributes that are on account but not on cos
 	v(ZMProv.new('desc','-ni','-v','account'))do |mcaller,data|
    mcaller.pass = data[0]==0 && data[1].include?('zimbraAdminConsoleUIComponents')
	end,
	
	v(ZMProv.new('desc','-ni','-v','cos'))do |mcaller,data|
    mcaller.pass = data[0]==0 && !data[1].include?('zimbraAdminConsoleUIComponents')
	end,
  
  v(ZMProv.new('desc','-ni','ucService'))do |mcaller,data|
    mcaller.pass = data[0] == 0 &&
                   data[1].split(/\n/).select {|w| w =~ /Presence/}.sort == ['zimbraUCPresenceURL', 'zimbraUCPresenceSessionId'].sort
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
