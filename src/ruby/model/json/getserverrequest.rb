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
    
    class Server < String
      def initialize(server)
        super(server.class == String ? super(server) : server['name'])
        @id = nil
        @attributes = {}
        if server.class == Hash
          @id = server['id']
          @attributes = server['a']
        end
      end
      
      def to_jh
        {
          'server' => {'json_class' => self.class.name, "_content" => self.to_s, 'by' => 'name'}
        }
      end
      
      def to_json(*a)
        to_jh.to_json(*a) 
      end
      
      def self.json_create(o) 
        puts *o
        new(*o['_content']) rescue nil
      end
      
      def id
        @id
      end
    end
    
    class GetServerRequest < Request
    
      def initialize(admin, server)
        super(admin)
        @name = server.class == Server ? server : Server.new(server)
        #puts YAML.dump(self)
        @port = 7071 
        @payload[:content] = @name
      end
      
      def body_to_jh
        {'Body' => {'GetServerRequest' => @payload[:content].to_jh.merge({'_jsns' => 'urn:zimbraAdmin'})}}
      end
            
      def to_jsonx(*a)
        to_jh.to_json(*a)
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
      class GetServerRequestTest < Test::Unit::TestCase     
        def testRun         
          testObject = GetServerRequest.new(User.new("admin", "apassw", "atoken", "sid"), Server.new(Model::TARGETHOST.to_str))
          puts YAML.dump(testObject.to_json)
          restore = JSON.parse(testObject.to_json.gsub(/\"json_class\":\"[^\"]*\",?/,''))
          assert(restore['Body']['GetServerRequest']['server']['_content'] == Model::TARGETHOST.to_str)
          assert(restore['Body']['GetServerRequest']['server']['by'] == 'name')
          assert(restore['Header']['context']['id'] == "sid")
          assert(restore['Header']['context']['authToken'] == "atoken")
        end  
      end 
    end
  end
end
