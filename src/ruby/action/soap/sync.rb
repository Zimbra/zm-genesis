#!/usr/bin/ruby -w
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end
require 'action/soap/command'  
require 'model/testbed'
 
require 'net/http'
require "yaml"

module Action::Soap
  
  class Sync < Action::Soap::Command
    
    def initialize(user = nil, host = Model::Host.new(Model::Servers.getServersRunning("mailbox").first), port = 443)
      super()      
      @user = user
      @host = host
      @port = port  
      @response = nil
      @template = @@template%['%s','%s','<SyncRequest xmlns="urn:zimbraMail"/>']
    end
    
    def run
      if(@user != nil)
        @host ||= @@run_env[MAILPORT]
        http = Net::HTTP.new(@host,@port)
        http.use_ssl = true if @port == 443
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        (http.set_debug_output $stdout) if $DEBUG
        http.start { |x|
          dataOut = @template%[@user.token, @user.sessionid]
          @response = x.post('/service/soap/', dataOut)          
          YAML::dump(@response) if $DEBUG
        } 
      end
    end 
  end
end
 
if $0 == __FILE__
require "login" 

user = Model::QA04.cUser('admin',Model::DEFAULTPASSWORD)
testme = Action::Soap::Login.new(user,Model::QA04) 
testme.run 
testme2 = Action::Soap::Sync.new(user,Model::QA04)
testme2.run
end