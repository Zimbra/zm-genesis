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

    class SaveWikiRequest < Request
    
      def initialize(user, name, id, content)
        super(user) 
        @uri = '/service/soap/'
        @name = name
        @id = id
        @content = content
      end

      def body_to_jh
        wikiPage = {'w' => {'name' => @name, 'l' => @id, '_content' => @content}}
        {'Body' => {'SaveWikiRequest' => wikiPage}.merge({'_jsns' => 'urn:zimbraMail'})}
      end
      
      def to_str
        "Action: Json " + self.class.name
      end
      
      def self.json_create(o)
        new(*o['Body']['SaveWikiRequest']) rescue nil
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
      class SaveWikiRequestTest < Test::Unit::TestCase     
        def testRun         
          testObject = SaveWikiRequest.new(Model::User.new("wikiacct", 'testid', "testme"))
          puts YAML.dump(testObject.to_json)
          restore = JSON.parse(testObject.to_json.gsub(/\"json_class\":\"[^\"]*\",?/,''))
          assert(restore['Body']['SaveWikiRequest']['m']['id'] == "testid")
          assert(restore['Body']['SaveWikiRequest']['m']['html'] == "1")
          assert(restore['Body']['SaveWikiRequest']['m']['read'] == "1")
        end  
      end 
    end
  end
end
