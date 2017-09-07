#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$

if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end 
require 'action/command'
require 'action/soap/clientauthhandler'
require 'model/testbed'
 
require 'soap/rpc/driver'
require 'soap/header/simplehandler'

module Action::Soap
  
  class Login < Action::Command
    attr_reader :token, :sessionid, :lifetime
    
    def initialize(user = nil , host = Model::Host.new(Model::Servers.getServersRunning("mailbox").first), port= 443)
      super()
      @user = user 
      @host = host
      @port = port
      @namespace = 'urn:zimbraAccount'
      @token = nil
      @lifetime = nil
      @sessionid = nil
      @response = nil       
    end
    
    def run
      if(@user != nil)    
        @host ||= @@run_env[MAILPORT] 
        @namespace ||= @@run_env[NAMESPACE]
        url = "https://#{@host}:#{@port}/service/soap/"
        s = SOAP::RPC::Driver.new(url, @namespace)
        s.options["protocol.http.ssl_config.verify_mode"] = nil
        s.add_method("AuthRequest", "account", "password") 
        #s.wiredump_dev = $stdout #debug option
        begin 
          @token, @lifetime, @sessionid =s.AuthRequest(@user.name.to_s,@user.password.to_s)       
          @response = [@token, @lifetime, @sessionid] 
        rescue
          @token = -1
          @lifetime = -1
          @sessionid = -1
        end
        @user.token = @token
        @user.sessionid = @sessionid
      end
    end
    
    def to_str
      "Action: Login #{@host}:#{@port}:#{@user}"
    end
    
  end
end
 
if $0 == __FILE__ 
user = Model::QA04.cUser('admin',Model::DEFAULTPASSWORD)  
testme = Action::Soap::Login.new(user, Model::QA04, 80) 
puts YAML.dump(testme.run)
end
