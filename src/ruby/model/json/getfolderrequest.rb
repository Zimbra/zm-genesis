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

    class GetFolderRequest < Request
    
      def initialize(user)
        super(user) 
        @uri = '/service/soap/'
        #@payload[:content] = msgid
      end

      def body_to_jh
        #msg = {'m' => {'id' => @payload[:content], 'html' => '1', 'read' => '1'}}
        {'Body' => {'GetFolderRequest' => {}}.merge({'_jsns' => 'urn:zimbraMail'})}
      end
      
      def to_str
        "Action: Json " + self.class.name
      end
      
      def self.json_create(o)
        new(*o['Body']['AuthRequest']['account']) rescue nil
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
      class SendMsgRequestTest < Test::Unit::TestCase     
        def testRun         
          testObject = GetFolderRequest.new(Model::User.new("hi", "testme"))
          puts YAML.dump(testObject.to_json)
          restore = JSON.parse(testObject.to_json.gsub(/\"json_class\":\"[^\"]*\",?/,''))
          assert(restore['Body']['GetFolderRequest']['m']['id'] == "testid")
          assert(restore['Body']['GetFolderRequest']['m']['html'] == "1")
          assert(restore['Body']['GetFolderRequest']['m']['read'] == "1")
        end  
      end 
    end
  end
end
