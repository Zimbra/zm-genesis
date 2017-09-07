#!/usr/bin/ruby
require 'soap/rpc/driver'
require 'soap/driver'
require 'soap/header/simplehandler'
if $0 == __FILE__
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
  
  
  drv = SOAP::RPC::Driver.new('https://qa04.lab.zimbra.com:7071/service/admin/soap/', 'urn:zimbraAdmin')
  
  drv.wiredump_dev = STDERR  #if $DEBUG
  drv.options["protocol.http.ssl_config.verify_mode"] = nil 
  drv.add_method('GetAllAdminAccountsRequest')
  drv.add_method('AuthRequest',"name", "password")
  
  token, lifetime, sessionid = drv.AuthRequest('admin@qa04.lab.zimbra.com',Model::DEFAULTPASSWORD)
  drv.headerhandler << ClientAuthHeaderHandler.new(sessionid, token) 
  p drv.GetAllAdminAccountsRequest()
end