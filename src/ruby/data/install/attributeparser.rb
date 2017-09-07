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
 
mypath = 'data'
if($0 =~ /data\/genesis/)
  mypath += '/genesis'
end

require "action/block"
require "action/runcommand" 
require 'rexml/document'
include REXML


module Action # :nodoc
  class AttributeParser < Action::RunCommand
    attr :filename, false
    attr :attributes, false
    attr :doc, false
    #
    # Objection creation
    # 
    def initialize(category = 'cos', filename = 'conf/attrs/zimbra-attrs.xml')
      super("cat", 'root', File.join(Command::ZIMBRAPATH,filename))
      @filename = filename
      @category = category
      @defaultElem = case category
                       when "cos"           then "defaultCOSValue"
                       when "globalConfig"  then "globalConfigValue"
                       when "server"        then "globalConfigValue"
                       when "domain"        then "globalConfigValue"
                       when "account"       then "defaultCOSValue|globalConfigValue"
                       when "mailRecipient" then "default"
                       else                     "desc"
                     end
      @defaultUpgrade = case category
                          when "cos"           then "defaultCOSValueUpgrade"
                          when "globalConfig"  then "globalConfigValueUpgrade"
                          when "server"        then "globalConfigValueUpgrade"
                          when "domain"        then "globalConfigValueUpgrade"
                          when "account"       then "defaultCOSValueUpgrade|globalConfigValueUpgrade"
                          when "mailRecipient" then "default"
                          else                     "desc"
                        end
      @attributes = {}
    end
        
     
    #
    # Execute  action
    # filename is stored inside @@filename at object initilization time 
    def run 
      begin
        iResult = super[1]   
        @doc = Document.new iResult.slice(iResult.index('<?xml version'), iResult.index('</attrs>') - iResult.index('<?xml version') + '</attrs>'.length)
        @doc.elements.each("/attrs/attr") do
          |attr|
          next if (!attr.attributes["optionalIn"] || attr.attributes["optionalIn"] !~ /\b#{@category}\b/) &&
                  (!attr.attributes["requiredIn"] || attr.attributes["requiredIn"] !~ /\b#{@category}\b/)
          defaultVal = attr.attributes["optionalIn"] ? [attr.attributes["optionalIn"]] : [attr.attributes["requiredIn"]]
          #defaultVal = [attr.elements["desc"].text] if attr.elements["desc"]
          defaultVal = ["Skip - no default"] if attr.elements["desc"]
          if attr.elements[@defaultElem] != nil
            defaultVal = []
            attr.elements.each(@defaultElem) { |w| defaultVal.push(w.text)}
          end
          attrName = attr.attributes["name"]
          val = case attr.attributes['type']
                  when 'integer' then (attr.attributes['min'].nil? ? "" : attr.attributes['min']) + "," + (attr.attributes['max'].nil? ? "" : attr.attributes['max'])
                  else attr.attributes['value']
                end
          @attributes[attrName] = {'type' => attr.attributes['type'],
                                   'value' => val,
                                   'mandatory' => attr.attributes["optionalIn"] ? false : true,
                                   'default' => defaultVal.uniq,
                                   'deprecatedSince' => attr.attributes["deprecatedSince"] # ? false : true,
                                  }
        end
    	  [0, iResult]
	    rescue => e
        puts e 
        puts e.backtrace()
	      [1, 'Unknown']
	    end
	    @attributes
	  end
 
    def lastId
      #@doc.elements.collect("/attrs/attr") { |attr| attr.attributes["id"].to_i}.sort.last
      #the following works in all versions
      id = -1
      @doc.elements.each("/attrs/attr") {|attr| id = attr.attributes['id'].to_i > id ? attr.attributes['id'].to_i : id}
      id
    end
    
    def upgradeValue(name)
      begin
        defaultValUpgrade = ["Skip - no default"]
        @doc.elements.each("/attrs/attr") do |attr|
          if attr.attributes["name"] == name
            if attr.elements[@defaultUpgrade]
              defaultValUpgrade = []
              attr.elements.each(@defaultUpgrade) { |w| defaultValUpgrade.push(w.text)}
            else
              defaultValUpgrade = @attributes[name]['default']
            end
            return defaultValUpgrade
          end
        end
      rescue => e
        puts e
        puts e.backtrace()
        @attributes[name]['default']
      end

    end
    
    def to_str
      "Action:buildparser file:#{@filename}"
    end   
  end
end  

if $0 == __FILE__
  require 'test/unit'  
  include Action
  
   
  # Unit test cases for Proxy
  class AttributeParserTest < Test::Unit::TestCase     
    def testNoArgument 
      testOne = AttributeParser.new
      assert(testOne.filename == '/opt/zimbra/conf/attrs/zimbra-attrs.xml')
      assert(testOne.category == 'cos')
      assert(testOne.defaultElem == 'defaultCOSValue')
    end      
  end   
end