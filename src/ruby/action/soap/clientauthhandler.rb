#!/usr/bin/ruby -w
require 'soap/rpc/driver'
require 'soap/header/simplehandler'

module Action::Soap
  class ClientAuthHeaderHandler < SOAP::Header::SimpleHandler
    MyHeaderName = XSD::QName.new("urn:zimbra", "context")
    
    def initialize(sessionid = nil, authtoken = nil)
      super(MyHeaderName)
      @sessionid = sessionid
      @authtoken = authtoken       
    end
    
    def on_simple_outbound
      if @sessionid
        { "sessionId" => @sessionid, "authToken" => @authtoken }
      end     
    end 
  end
end
