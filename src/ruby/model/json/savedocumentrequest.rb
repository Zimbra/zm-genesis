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
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 

require 'json'
require 'model/json/request'

module Model 
  module Json

    class SaveDocumentRequest < Request
    
      def initialize(user, name, id, content)
        super(user) 
        @uri = '/service/soap/'
        @name = name
        @id = id
        @content = content
      end

      def body_to_jh
        docPage = {'doc' => {'name' => @name, 'l' => @id, 'ct' => "application/x-zimbra-doc", 'content' => @content}}
        {'Body' => {'SaveDocumentRequest' => docPage}.merge({'_jsns' => 'urn:zimbraMail'})}
      end
      
      def to_str
        "Action: Json " + self.class.name
      end
      
      def self.json_create(o)
        new(*o['Body']['SaveDocumentRequest']) rescue nil
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
      class SaveDocumentRequestTest < Test::Unit::TestCase     
        def testRun         
          testObject = SaveDocumentRequest.new(Model::User.new("docacct", 'testid', "testme"))
          puts YAML.dump(testObject.to_json)
          restore = JSON.parse(testObject.to_json.gsub(/\"json_class\":\"[^\"]*\",?/,''))
          assert(restore['Body']['SaveDocumentRequest']['m']['id'] == "testid")
          assert(restore['Body']['SaveDocumentRequest']['m']['html'] == "1")
          assert(restore['Body']['SaveDocumentRequest']['m']['read'] == "1")
        end  
      end 
    end
  end
end
