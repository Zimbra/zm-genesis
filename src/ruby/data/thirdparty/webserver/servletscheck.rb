#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 

mypath = 'data'
if($0 =~ /data\/genesis/)
  mypath += '/genesis'
end

require "model" 
require "action/block"
require "action/runcommand" 
require "action/verify"
require "#{mypath}/install/configparser"
require "action/zmprov"
require 'rexml/document'
include REXML

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Servlets test"

include Action 


#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [
  #curl -s -m 20 -Ik http(s)://mail....com/zimbra/
  #TODO add support for all modes
  #     go through nginx on proxy enabled deployments
  v(cb("servlet test", 300) do
    exitCode = 0 
    result = {}
    mObject = ConfigParser.new()
    mResult = mObject.run
    servers = mObject.getServersRunning('store')
    modeAttr = 'zimbraMailMode'
    portSuffix = 'Port'
    murlAttr = 'zimbraMailURL'
    servers = mObject.getServersRunning('proxy')
    if !servers.empty?
      modeAttr = 'zimbraReverseProxyMailMode'
    end
    servers = mObject.getServersRunning('store') #if mObject.getServersRunning('proxy').empty?
    servers.each do |host|
      mUrl = ZMProv.new('gs', host, murlAttr).run[1][/#{murlAttr}:\s+(\S+)/, 1]
      mode = ZMProv.new('gs', host, modeAttr).run[1][/#{modeAttr}:\s+(\S+)/, 1]
      mode = mode == 'http'? mode : 'https'
      portAttr = 'zimbraMail' + (mode == 'http' ? '' : 'SSL') + portSuffix
      port = ZMProv.new('gs', host, portAttr).run[1][/#{portAttr}:\s+(\S+)/, 1]
      url = URI.parse("#{mode}://#{host}:#{port}#{mUrl}" + (mUrl[-1,1] == '/' ? '' : '/'))
      mObject = RunCommand.new(File.join(Command::ZIMBRACOMMON,'bin', 'curl'), Command::ZIMBRAUSER,
                               '-s', '-m', '20', '-Ik', url)
      mResult = mObject.run
      if mResult[1] !~ /HTTP\/\S+ 200 OK/
        exitCode += 1
        result[host] = mResult[1]
      end
    end
    [exitCode, result]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 #&& data[1].select { |w| w[2] == nil}.empty?
    if (not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      msgs = {}
      data[1].each_pair do |k,v|
        msgs[k] = {"IS" => v.split(/\n/).first, "SB" => '200 OK'}
      end
      mcaller.badones = {'servlets test' => msgs}
    end
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