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
    
    class SendMsgRequest < Request
    
      def initialize(user, to, subj, msg)
        super(user) 
        @uri = '/service/soap/'
        @payload[:content] = @user
        @to = to.to_s
        @subj = subj
        @msg = msg
      end
      
      def body_to_jh
        recipient = {'e' => {'t' => 't', 'a' => @to}}
        subject = {'su' => @subj}
        mimeparts = {'mp' => {'ct' => 'text/plain', 'content' => @msg}}
        msg = {'m' => recipient.merge(subject).merge(mimeparts)}
        {'Body' => {'SendMsgRequest' => msg}.merge({'_jsns' => 'urn:zimbraMail'})}
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
          testObject = SendMsgRequest.new(Model::User.new("hi", "testme"), "dest", "testsubject", "testmsg")
          puts YAML.dump(testObject.to_json)
          restore = JSON.parse(testObject.to_json.gsub(/\"json_class\":\"[^\"]*\",?/,''))
          assert(restore['Body']['SendMsgRequest']['m']['su'] == "testsubject")
          assert(restore['Body']['SendMsgRequest']['m']['mp']['content'] == "testmsg")
          assert(restore['Body']['SendMsgRequest']['m']['e']['a'] == "dest")
        end  
      end 
    end
  end
end
