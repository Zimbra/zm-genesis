#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
#
#
if($0 == __FILE__)
  #$:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?ybur/,"").reverse; $:.unshift(File.join(mydata, 'ruby')) 
end
require 'json'

require 'action/json/command' 
 

 
module Action::Json
  class AdminLogin < Action::Json::Command
    def initialize(cname, host=Model::Host.new(Model::Servers.getServersRunning("mailbox").first),
                   port=7071, cmode='https') 
      super
    end
    
    def run
      super
      if @response.class == Net::HTTPOK
        body = JSON::parse(@response.body)['Body']
        @request.user.sessionid = body['AuthResponse']['sessionId']['id'] if body['AuthResponse'].has_key?('sessionId')
        #WORKAROUND: handle the change in the response that occured between RC1 and GA:
        #              - GNR up to RC1 authToken is a String
        #              - GNR GA and after authToken is an Array
        if body['AuthResponse']['authToken'].instance_of?(String)
           @request.user.token = body['AuthResponse']['authToken']
         else
           @request.user.token = body['AuthResponse']['authToken'].first['_content']
        end
      end
    end
  end
  
  class Login < Action::Json::Command
    def initialize(cname, host=Model::Host.new(Model::Servers.getServersRunning("mailbox").first),
                   port=443, cmode='https') 
      super
    end
    
    def run
      super
      if @response.class == Net::HTTPOK
        body = JSON::parse(@response.body)['Body']
        @request.user.sessionid = body['AuthResponse']['sessionId']['id'] if body['AuthResponse'].has_key?('sessionId')
        if body['AuthResponse']['authToken'].instance_of?(String)
           @request.user.token = body['AuthResponse']['authToken']
         else
           @request.user.token = body['AuthResponse']['authToken'].first['_content']
        end
      end
    end
  end

end

if $0 == __FILE__
  require 'test/unit'  
  include Action
  
   
    # Unit test cases for Proxy
    class CommandTest < Test::Unit::TestCase     
      def testNoArgument 
        testOne = Action::Json::Login.new
        puts YAML.dump(testOne.to_json)
        puts YAML.dump(JSON.parse(testOne.to_json))
        assert(testOne.timeOut == 60)
      end      
    end   
end
 
    
     
