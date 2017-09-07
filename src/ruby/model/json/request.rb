#!/bin/env ruby
#
# = action/untar.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# Part of the command class structure.  This implements user data model
# 
require 'json'

if($0 == __FILE__) 
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?ybur/,"").reverse; $:.unshift(File.join(mydata, 'ruby')) 
end 


module Model 
  module Json
    
    class Request
      attr :payload
      attr :uri
      attr :user
      
      def initialize(user)
        @user = user
        @payload = {:json_class => self.class.name,
                    :content => {},
                    :header => {}}
        @uri = '/service/admin/soap/'
      end
      
      def body_to_jh
        {'Body' => @payload[:content]}
      end
      
      def header_to_jh
        {'Header' => {'context' => {'_jsns' => 'urn:zimbra',
                                    'id' => @user.sessionid,
                                    'authToken' => @user.token
                                   }
                     }
        }
      end
      
      def to_jh
        {'json_class' => self.class.name}.merge(body_to_jh).merge(header_to_jh).merge({'_jsns' => 'urn:zimbraSoap'})
      end
        
      def to_json(*a)
        to_jh.to_json(*a) 
      end
      
      def self.json_create(o) 
        new(*o) rescue nil
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
      class UserTest < Test::Unit::TestCase     
        def testRun         
          testObject = Model::Json::Request.new(Model::User.new("hi", "testme", "testToken", "testid"))
          restore = JSON.parse(testObject.to_json.gsub(/\"json_class\":\"[^\"]*\",?/,''))
          assert(restore['Header']['context']['id'] == "testid")
          assert(restore['Header']['context']['authToken'] == "testToken")
        end  
      end 
    end
  end
end
