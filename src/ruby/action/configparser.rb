#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2007 Zimbra
#
#

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "action/runcommand" 
require 'rexml/document'
include REXML


module Action # :nodoc
  class ConfigParser < Action::RunCommand
    attr :filename, false
    attr :attributes, false
    attr :doc, false
    #
    # Objection creation
    # 
    def initialize(filename = File.join('.uninstall', 'config.xml'))
      super("cat", 'root', File.join(Command::ZIMBRAPATH,filename))
      @filename = File.join(Command::ZIMBRAPATH,filename)
    end
     
    #
    # Execute  action
    # filename is stored inside @@filename at object initilization time 
    def run 
      begin
        iResult = super[1]    		 
        @doc = Document.new iResult.slice(iResult.index('<?xml version'), iResult.index('</plan>') - iResult.index('<?xml version') + '</plan>'.length)
        [0, doc]
	  rescue
	    [1, 'Unknown']
	  end
    end
    
    def isPackageInstalled(package)
      begin
        found = false
        doc.each_element_with_attribute('name', package, 0, '//package') do
          |pkg|
          if pkg.attribute('name').value == package && (pkg.parent.attributes['name'].to_s == Model::TARGETHOST.to_s ||
             (pkg.parent.elements['zimbrahost'] != nil && pkg.parent.elements['zimbrahost'].attributes['name'].to_s == Model::TARGETHOST.to_s))
            found = true
            break
          end
        end
        return found
      rescue
        return false
      end
    end

    def hasOption(package, name, value = nil)
      begin
        found = false
        doc.each_element_with_attribute('name', package, 0, '//package') do |pkg|
          if pkg.attribute('name').value == package && (pkg.parent.attributes['name'].to_s == Model::TARGETHOST.to_s ||
             (pkg.parent.elements['zimbrahost'] != nil && pkg.parent.elements['zimbrahost'].attributes['name'].to_s == Model::TARGETHOST.to_s))
            pkg.elements.each('//option') do |opt|
              if opt.attributes['name'] == name
                if value == nil
                  found = opt.text.strip
                else
                  found = opt.text.strip == value
                end
                #found = true
                break    
              end
            end
          end
        end
        return found
      rescue
        return false
      end
    end
    
    def requireCommercialCert
      begin
        found = false
        doc.each_element_with_attribute('name', 'certInstall', 0, '//plugin') do |pkg|
          pkg.elements.each('//option') do |opt|
            if opt.attributes['name'] == 'host' && opt.text.strip == Model::TARGETHOST.to_s
              found = true
              break    
            end
          end
        end
        return found
      rescue
        return false
      end
    end
    
    def getServersRunning(service)
      begin
        servers = []
        doc.each_element_with_attribute('name', nil, 0, '//package') do |pkg|
          if pkg.attribute('name').value =~ /zimbra-#{service}\b/
            zhost = pkg.parent.elements['zimbrahost']
            if zhost == nil
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
    
    def getAllServers()
      servers = []
      begin
        doc.elements.each("//host") do |host|
          servers.push(host.attributes['name'].chomp.strip)
        end
      rescue
      end
      servers
    end
    
    def expectedTimezone
      mObject = ConfigParser.new()
      mObject.run
      res = nil
      mObject.doc.elements.each("//option") do |option|
        if option.attributes['name'] == 'zimbraPrefTimeZoneName'
          res = option.text.chomp.strip
          return res
        end
        res
      end
    end
    
    def zimbraCustomized(host, command, area, attr)
      begin
        target = host.instance_of?(Model::Host) ? host.to_s : host
        mTarget = nil
        mCmd = nil
        mParams = nil
        case area
          when 'globalConfig'
            mArea = 'mcf'
          when 'server'
            mArea = 'ms'
          when 'cos'
            mArea = 'mc'
          when 'domain'
            mArea = 'md'
          else
            mArea = nil
        end
        doc.each_element_with_attribute('name', 'runZmCommand', 0, '//plugin') do |plug|
          plug.elements.each('option') do |opt|
            mTarget = opt.text.strip if opt.attributes['name'] == 'host'
            mCmd = opt.text.strip if opt.attributes['name'] == 'cmd'
            mParams = opt.text.strip if opt.attributes['name'] == 'parms'
          end
          return mParams if (mTarget == target || mArea != 'server') && mCmd =~ /#{command}/ && mParams =~ /\b#{mArea}\s+.*\b#{attr}\b/
        end
      rescue
      end
      return false
    end
    
    def to_str
      "Action:ConfigParser file:#{@filename}"
    end   
  end
  
  def isClustered(host)
    doc.each_element_with_attribute('name', host, 0, '//zimbrahost') do |h|
      return true if h.parent.parent.name == 'cluster'
    end
    false
  end
  
end


if $0 == __FILE__
  require 'test/unit'  
  include Action
  
   
  # Unit test cases for Proxy
  class ConfigParserTest < Test::Unit::TestCase     
    def testNoArgument 
      testOne = ConfigParser.new
      assert(testOne.filename == '/opt/zimbra/.uninstall/config.xml')
      testOne.run
      assert(!testOne.isPackageInstalled('zimbra-core'))
      assert(!testOne.hasOption('zimbra-ldap', 'LDAPPASS', 'test1234'))
    end   
    
    def testServersRunning 
      testTwo = ConfigParser.new
      testTwo.run
      puts testTwo.getServersRunning('convertd')
      assert(testTwo.getServersRunning('convertd') != [])
    end  
  end   
end