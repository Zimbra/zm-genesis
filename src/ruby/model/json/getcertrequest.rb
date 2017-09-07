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
    
    class ServerBy < String
      def initialize(name, kind='name')
        super(name)
        @by = kind == 'name' ? kind : 'id'
      end
      
      def to_jh
        {
          'server' => {'json_class' => self.class.name, "_content" => self.to_s, 'by' => @by}
        }
      end
      
      def to_json(*a)
        to_jh.to_json(*a) 
      end
      
      def self.json_create(o) 
        new(*o['_content']) rescue nil
      end
    end
    
    class GetCertRequest < Request
    
      def initialize(admin, server)
        super(admin)
        @port = 7071 
        @payload[:content] = server
      end
      
      def body_to_jh
        {'Body' => {'GetCertRequest' => {'type' => 'all', 'server' =>@payload[:content].to_str}.merge({'_jsns' => 'urn:zimbraAdmin'})}}
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
      class GetCertRequestTest < Test::Unit::TestCase     
        def testRun         
          testObject = GetCertRequest.new(User.new("admin", "apassw", "atoken", "sid"), '123456')
          puts YAML.dump(testObject.to_json)
          restore = JSON.parse(testObject.to_json.gsub(/\"json_class\":\"[^\"]*\",?/,''))
          assert(restore['Body']['GetCertRequest']['server'] == '123456')
          assert(restore['Body']['GetCertRequest']['type'] == 'all')
          assert(restore['Header']['context']['id'] == "sid")
          assert(restore['Header']['context']['authToken'] == "atoken")
        end  
      end 
    end
  end
end
