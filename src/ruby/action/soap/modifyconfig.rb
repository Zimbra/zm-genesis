#!/usr/bin/ruby -w
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end 

require 'net/http'
require 'net/https'
require 'action/soap/command'
require 'model/testbed'
 
module Action
  module Soap   
  
    class ModifyConfig < Action::Soap::Command
      attr_reader :token, :sessionid, :lifetime
      
      def initialize(user = nil , changeSetting = {},
                     host = Model::Host.new(Model::Servers.getServersRunning("mailbox").first), port = 7071)
        super()
        @user = user 
        @host = host
        @port = port
        @namespace = 'urn:zimbraAdmin'        
        @changeSetting = changeSetting 
        @response = nil       
      end
      
      def run
        if(@user != nil)     
          @host ||= @@run_env[MAILPORT]
          http = Net::HTTP.new(@host.name, @port)  
          #http.set_debug_output $stdout
          command = ["<ModifyConfigRequest xmlns=\"#{@namespace}\">"]
          @changeSetting.each do |key, value|
            if value.respond_to?(:each)
              value.each do |x|
                command = command << "<a n=\"#{key}\">#{x}</a>"
              end
            else
              command = command <<  "<a n=\"#{key}\">#{value}</a>"
            end
          end 
          command = (command << "</ModifyConfigRequest>").join("\n")           
          http.use_ssl = true if @port == 7071
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          http.start do |x|
            dataOut = @@admintemplate%[@user.token, @user.sessionid, command]    
            @response = x.post('/service/admin/soap/', dataOut, 
            {'Content-Type' => 'text/xml;charset=us-ascii',
              'SOAPAction' => '', 
            })           
          end
        end     
         
      end
      
      def to_str
        "Action: ModifyConfig #{@host}:#{@port}:#{@changeSetting}"
      end
      
    end
  end
end
 
if $0 == __FILE__ 
  require 'action/soap/adminlogin'
  user = Model::QA04.cUser('admin',Model::DEFAULTPASSWORD) 
  testme = Action::Soap::AdminLogin.new(user, Model::QA04) 
  testme.run   
  testme2 = Action::Soap::ModifyConfig.new(user, {'zimbraHsmAge' => '1d'})
  testme2.run   
  #puts YAML.dump(testme2)
 
end