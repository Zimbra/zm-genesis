#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2010 Zimbra
#
# setup for multinode 

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"
require "action/block"
require "action/zmprov"

current = Model::TestCase.instance()
current.description = "Check to see if the system is multinode"
 
include Action

module HostQueryService
  attr :multinode, true
  attr :serverList, true
  attr :services, true

  def conStructHosts(servers = [], serverList = [])
    serverList = [] if serverList.nil?
    #data is in form of [[host,service]...]
    
    servers.each do |host, services|
      unless(host == self.to_s)
        hostName, domainName = host.split('.',2)
        curServer = Model::Host.new(hostName, Model::Domain.new(domainName))
        class << curServer
          include HostQueryService
        end
      else
        curServer = self
      end
      serverList.push(curServer)
      curServer.services = services
    end 
    serverList
  end

  def findService(service, server = self)
    serverList.select do |curServer|
      curServer.services.has_key?(service)
    end
  end
end

class ServerMap
  #only get hosts with hostEnabled
  def filterHost(hostList)
    hostList.split(/\n/).map do |server|
      sanServer = server.chomp rescue server
      data = ZMProv.new('-l', 'gs', sanServer, 'zimbraServiceEnabled').run[1] rescue ""
      [sanServer , parseService(data.split(/\n/))]
    end

  end
  
  def parseService(serviceList)
   #data is of form 'zimbraserviceEnabled: xxxx'
   #clean, filter to array than transform to hash
   Hash[*serviceList.select{|x| x.include?('zimbraServiceEnabled') }.map do |line|
          data = line.split(': ')[1].chomp rescue nil
        end.compact.map {|y| [y.to_sym, true]}.flatten]
  end

  def map(host)
    result = ZMProv.new("gas").run
    serviceList = filterHost(result[1]) rescue []
    class << host
      include HostQueryService
    end
    host.multinode = (serviceList.size > 1) rescue false
    host.serverList = host.conStructHosts(serviceList)
  end

end
 
#
# Setup
#
current.setup = [
   
]

#
# Execution
#
current.action = [     
                  cb("Check to see if system is multinode") do
                    ServerMap.new.map(Model::TARGETHOST)
                  end
                 ]

#
# Tear Down
#
current.teardown = [        
   
]

if($0 == __FILE__)
  require 'engine/simple'
  require 'yaml'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
  puts YAML.dump(Model::TARGETHOST)
end
