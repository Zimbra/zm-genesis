#!/usr/bin/ruby -w
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end 
require 'action/soap/command'
require 'soap/rpc/driver' 
require 'soap/header/simplehandler'
require 'model/testbed'
 
module Action
  module Soap
#    class AdminClientAuthHeaderHandler < SOAP::Header::SimpleHandler
#        MyHeaderName = XSD::QName.new("urn:zimbra", "context")
#        
#        def initialize(sessionid = nil, authtoken = nil)
#          super(MyHeaderName)
#          @sessionid = sessionid
#          @authtoken = authtoken       
#        end
#        
#        def on_simple_outbound
#          if @sessionid
#            { "sessionId" => @sessionid, "authToken" => @authtoken }
#          end     
#        end 
#    end

  
    class AdminLogin < Action::Soap::Command
      attr_reader :token, :sessionid, :lifetime
      
      def initialize(user = nil , host = Model::Host.new(Model::Servers.getServersRunning("mailbox").first), port= 7071)
        super()
        @user = user 
        @host = host
        @port = port
        @namespace = 'urn:zimbraAdmin'
        @token = nil
        @lifetime = nil
        @sessionid = nil
        @response = nil     
        @domainAdmin = nil  
      end
      
      def run
        if(@user != nil)    
          @host ||= @@run_env[MAILPORT] 
          @namespace ||= @@run_env[NAMESPACE]       
          s = SOAP::RPC::Driver.new(@@adminurl%[@host, @port], @namespace)
          s.options["protocol.http.ssl_config.verify_mode"] = nil 
          s.add_method("AuthRequest", "name", "password") 
          #s.wiredump_dev = $stdout
          @token, @lifetime, @domainAdmin, @sessionid =s.AuthRequest(@user.name.to_s,@user.password.to_s)       
          @response = [@token, @lifetime, @sessionid] 
          @user.token = @token
          @user.sessionid = @sessionid   
        end
      end
      
      def to_str
        "Action: AdminLogin #{@host}:#{@port}:#{@user}"
      end
      
    end
  end
end
 
if $0 == __FILE__ 
user = Model::QA04.cUser('admin',Model::DEFAULTPASSWORD) 
testme = Action::Soap::AdminLogin.new(user, Model::QA04) 
testme.run
puts YAML.dump(testme)
end