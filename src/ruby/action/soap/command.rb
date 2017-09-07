#!/usr/bin/ruby -w
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end
require 'action/command' 
 

 
module Action::Soap  
  class Command < Action::Command  
  
    def initialize 
      super
    end
    
    @@template = ['<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">',
      '<soap:Header>',
      '<context xmlns="urn:zimbra">',
      '<authToken>%s</authToken>',
      '<sessionId>%s</sessionId>',
      '</context>',
      '</soap:Header>',
      '<soap:Body>',
      '%s', 
      '</soap:Body>',
      '</soap:Envelope>'].join("\n")
    
    @@admintemplate = [
      '<?xml version="1.0" encoding="us-ascii" ?>',
      '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">',
      '<soap:Header>',
      '<context xmlns="urn:zimbra">',
      '<authToken>%s</authToken>',
      '<sessionId>%s</sessionId>',
      '</context>',
      '</soap:Header>',
      '<soap:Body>',
      '%s', 
      '</soap:Body>',
      '</soap:Envelope>'].join("\n")
      
    #@@adminurl = 'http://%s:%s/service/admin/soap/'
    @@adminurl = 'https://%s:%s/service/admin/soap/'
    def soapString
       @response.body
    end    
        
    def inspect
      YAML.dump(self)
    end
    
    def response
      @response
    end
  end
end

if $0 == __FILE__
  require 'test/unit'  
  include Action
  
   
    # Unit test cases for Proxy
    class CommandTest < Test::Unit::TestCase     
      def testNoArgument 
        testOne = Action::Soap::Command.new
        assert(testOne.timeOut == 60)
      end      
    end   
end
 
    
     