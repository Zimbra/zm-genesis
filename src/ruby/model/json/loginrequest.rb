#!/usr/bin/ruby -w
#
# = action/untar.rb
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
    
    class LoginRequest < Request
    
      def initialize(user)
        super(user) 
        @uri = '/service/soap/'
        @payload[:content] = @user
      end
      
      def body_to_jh
        {'Body' => {'AuthRequest' => @payload[:content].to_jh.merge({'_jsns' => 'urn:zimbraAccount'})}}
      end
      
      def to_str
        "Action: Json " + self.class.name
      end
      
      def self.json_create(o)
        new(*o['Body']['AuthRequest']['account']) rescue nil
      end
    end
    
    class AdminLoginRequest < Model::Json::Request
    
      def initialize(user)
        super(user) 
      end
      
      def body_to_jh
        {'Body' => {'AuthRequest' => {'_jsns' => 'urn:zimbraAdmin',
                                      'name' =>  @user.name.to_s,
                                      'password' => @user.password.to_s
                                     },
                   }
        }
      end
      
      def to_str
        "Action: Json " + self.class.name
      end
      
      def self.json_create(o)
        new(*o['Body']) rescue nil
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
      class LoginTest < Test::Unit::TestCase     
        def testRun         
          testObject = LoginRequest.new(Model::User.new("hi", "testme"))
          puts YAML.dump(testObject.to_json)
          restore = JSON.parse(testObject.to_json.gsub(/\"json_class\":\"[^\"]*\",?/,''))
          assert(restore['Body']['AuthRequest']['account']['_content'] == "hi")
          assert(restore['Body']['AuthRequest']['password']['_content'] == "testme")
        end  
      end 
      
      class AdminLoginTest < Test::Unit::TestCase
        def testRun
          testObject = AdminLoginRequest.new(Model::User.new("hi", "testme")) 
          puts testObject.to_json.gsub(/\"json_class\":\"[^\"]*\",?/,'')
          restore = JSON.parse(testObject.to_json.gsub(/\"json_class\":\"[^\"]*\",?/,''))
          assert(restore['Body']['AuthRequest']['name'] == "hi")
          assert(restore['Body']['AuthRequest']['password'] == "testme")
        end
      end
    end
  end
end
