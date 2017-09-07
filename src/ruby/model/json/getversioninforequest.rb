#!/bin/env ruby
#
#
# Copyright (c) 2008 zimbra
#
# Written & maintained by Virgil Stamatoiu
#
# Documented by Virgil Stamatoiu
#
# Part of the command class structure.  This implements login request data model
# 

if($0 == __FILE__) 
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?ybur/,"").reverse; $:.unshift(File.join(mydata, 'ruby')) 
end 

require 'json'
require 'model/json/request'
require 'model/user'

module Model 
  module Json
    class GetVersionInfoRequest < Request
    
      def initialize(admin)
        super(admin)
        @port = 7071 
        #@payload[:content] = server
      end
      
      def body_to_jh
        {'Body' => {'GetVersionInfoRequest' => {'_jsns' => 'urn:zimbraAdmin'}}}
      end
      
      def to_str
        self.name
      end
  end
  end
end

if $0 == __FILE__
  require 'test/unit'  
  require 'yaml'
  
  require 'model'
  
  module Model
    module Json
      # Unit test cases
      class GetVersionInfoRequestTest < Test::Unit::TestCase     
        def testRun         
          testObject = GetVersionInfoRequest.new(User.new("admin", "apassw", "atoken", "sid"))
          #puts YAML.dump(testObject.to_json)
          restore = JSON.parse(testObject.to_json.gsub(/\"json_class\":\"[^\"]*\",?/,''))
          assert(restore['Body']['GetVersionInfoRequest']['_jsns'] == 'urn:zimbraAdmin')
          assert(restore['Header']['context']['id'] == "sid")
          assert(restore['Header']['context']['authToken'] == "atoken")
        end  
      end 
    end
  end
end
