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

module Model 
  module Json
    
    class GetAccountInfoRequest < Request
    
      def initialize(admin, account)
        super(admin)
        @account = account
        #puts YAML.dump(self)
        @port = 7071 
        @payload[:content] = @account.name
      end
      
      def body_to_jh
        {'Body' => {'GetAccountInfoRequest' => @payload[:content].to_jh.merge({'_jsns' => 'urn:zimbraAdmin'})}}
      end
            
      def to_jsonx(*a)
        to_jh.to_json(*a)
      end
      
      def to_str
        "Action: Json "
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
      class GetAccountInfoRequestTest < Test::Unit::TestCase     
        def testRun         
          testObject = GetAccountInfoRequest.new(User.new("admin", "apassw", "atoken", "sid"), Model::User.new("hi", "testme"))
          puts YAML.dump(testObject.to_json)
          restore = JSON.parse(testObject.to_json.gsub(/\"json_class\":\"[^\"]*\",?/,''))
          assert(restore['Body']['GetAccountInfoRequest']['account']['_content'] == "hi")
          assert(restore['Header']['context']['id'] == "sid")
          assert(restore['Header']['context']['authToken'] == "atoken")
        end  
      end 
    end
  end
end
