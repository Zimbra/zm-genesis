#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# service class to serve multinode configuration and proxy detection

if($0 == __FILE__)
    mydata = File.expand_path(__FILE__).reverse.sub(/.*?ledom/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 

require "action/zmprov"

include Action
module Model # :nodoc
  
  class Servers
    class << self
      
      @@multinode = nil
      @@serverList = nil
      @@proxy = nil
      @@serviceList = {}
      
      # returns true if current configuration has more than 1 server
      def isMultinode?
        if @@multinode.nil?
          @@multinode = getAllServers().size > 1
        end
        
        @@multinode
      end
      
      # returns string array of servers that have specified service running
      # use targethost if want to send request from other server
      def getServersRunning(service, targetHost = Model::TARGETHOST)
        unless @@serviceList.has_key?(service.to_s)
          @@serviceList[service] = ZMProv.new('-l', 'gas', service, targetHost).run[1].split(/\n/)
        end
        
        @@serviceList[service]
      end
      
      # returns string array of all servers
      # use targethost if want to send request from other server
      def getAllServers(targethost = Model::TARGETHOST)
        if @@serverList.nil?
          @@serverList = ZMProv.new('-l', 'gas', targethost).run[1].split(/\n/)
        end
        
        @@serverList
      end
      
      # returns true if current configuration has proxy installed
      def hasProxy?
        if @@proxy.nil?
          # before ZCS 8 service name was "imapproxy"
          @@proxy = ["proxy", "imapproxy"].any? { |srv| !getServersRunning(srv).empty? }
        end
        
        @@proxy
      end
      
      # reset all values to initial state
      def resetValues
        @@multinode = nil
        @@serverList = nil
        @@proxy = nil
        @@serviceList = {}
      end
    
    
    end
  end
  
end

if $0 == __FILE__
  require 'test/unit'  
  

end
 
  

