#!/usr/bin/ruby
#
#
# Example of document method
#
require 'soap/rpc/driver' 
require 'soap/header/simplehandler' 
require 'soap/marshal'
require 'benchmark'
require 'yaml'

include SOAP
 

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

 
drv = SOAP::RPC::Driver.new('https://qa04.lab.zimbra.com:7071/service/admin/soap/', mNS = 'urn:zimbraAdmin')
drv.default_encodingstyle = SOAP::EncodingStyle::LiteralHandler::Namespace
drv.wiredump_dev = STDERR  #if $DEBUG
drv.options["protocol.http.ssl_config.verify_mode"] = nil   

 
drv.add_method('AuthRequest', "name", "password") 
drv.add_document_method('GetAllAdminAccountsRequest', mNS, [XSD::QName.new(mNS, 'GetAllAdminAccountsRequest')],  
  [XSD::QName.new(mNS, 'GetAllAdminAccountsResponse')] )  
token, lifetime, sessionid = drv.AuthRequest('admin@qa04.lab.zimbra.com',Model::DEFAULTPASSWORD) 
drv.headerhandler << ClientAuthHeaderHandler.new(sessionid, token)  
response = drv.GetAllAdminAccountsRequest([])
 
 
def GetNamePair(response)
  response.account.each do |x| 
    class << x
      attr :configuration, true    
    end     
    x.configuration = Hash[*x.a.map do |y|
      [y.__xmlattr[XSD::QName.new(nil, 'n')], String.new(y)]
    end.flatten] 
  end
end

def GetNamePairTwo(response)
  response.account.each do |x| 
    class << x
      attr :configuration, true    
    end
    x.configuration = Hash.new 
    x.a.each do |y| 
      x.configuration[y.__xmlattr[XSD::QName.new(nil, 'n')]] = String.new(y)
    end 
  end  
end 
puts YAML.dump(response)
 