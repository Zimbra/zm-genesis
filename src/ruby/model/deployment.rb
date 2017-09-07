#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# expected install/upgrade configuration of the zimbra servers under test
# based on the configTemplate

if($0 == __FILE__)
    mydata = File.expand_path(__FILE__).reverse.sub(/.*?ledom/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 

require 'singleton'
require "action/runcommand"
require 'rexml/document'
include REXML

include Action
module Model # :nodoc
  
  class Deployment
    #class << self
      
    @@configuration
    @@filename
    
    attr :attributes, false
    #attr :doc, false
    #
    # Objection creation
    # 
    def initialize(filename = File.join('.uninstall', 'config.xml'))
      parse(filename)
    end
    
    def Deployment.parse(filename = File.join('.uninstall', 'config.xml'))
      if !defined?(@@configuration) || @@configuration.nil?
        @@filename = File.join(Command::ZIMBRAPATH,filename)
        mResult = RunCommand.new("cat", 'root', File.join(Command::ZIMBRAPATH,filename)).run
        if mResult[0] != 0
          return
        end 
        begin
          iResult = mResult[1]         
          @@configuration = Document.new iResult.slice(iResult.index('<?xml version'), iResult.index('</plan>') - iResult.index('<?xml version') + '</plan>'.length)
        rescue
          #@@configuration = nil
        end
      end
    end
      
    def Deployment.configuration
      @@configuration rescue nil
    end
    
    def Deployment.getServersRunning(service, asHost = true)
      parse()
      begin
        servers = []
        @@configuration.each_element_with_attribute('name', nil, 0, '//package') do |pkg|
          if pkg.attribute('name').value =~ /zimbra-#{service}\b/
            zhost = pkg.parent.elements['zimbrahost']
            if asHost || zhost == nil
              servers << pkg.parent.attributes['name'] if pkg.parent.attributes['type'] != 'standby'
            else
              servers << zhost.attributes['name']
            end
          end
        end
      rescue
        servers = []
      end
      servers.uniq
    end

    def Deployment.getAllServers()
      servers = []
      begin
        @@configuration.elements.each("//host") do |host|
        servers.push(host.attributes['name'].chomp.strip)
        end
      rescue
      end
      servers
    end      

  end
  
end

if $0 == __FILE__
  require 'test/unit'  
  

end
 
  

