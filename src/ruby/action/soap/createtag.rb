#!/usr/bin/ruby -w
#
# CreateTag command
#
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end
require 'action/soap/command'  
require 'model/testbed' 
require 'net/http'
require "yaml"

module Action::Soap
  
  class CreateTag < Action::Soap::Command
    
    def initialize(user, tagName, color, host = Model::Host.new(Model::Servers.getServersRunning("mailbox").first),
                   port = 443)
      super()      
      @user = user
      @host = host
      @port = port  
      @response = nil
      @tagName = tagName
      @color = color
      @template = @@template%['%s','%s','<CreateTagRequest xmlns="urn:zimbraMail">'+
      '<tag name="%s" color="%s"/></CreateTagRequest>']
    end
    
    def run
      if(@user != nil)
        @host ||= @@run_env[MAILPORT]
        http = Net::HTTP.new(@host.name, @port)
        http.use_ssl = true if @port == 443
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE        
        http.set_debug_output $stdout if $DEBUG       
        http.start { |x|
          dataOut = @template%[@user.token, @user.sessionid, @tagName, @color]
          @response = x.post('/service/soap/', dataOut, {'Content-Type' => 'text/xml;charset=us-ascii',
              'SOAPAction' => ''} 
           )           
        }  
      end
    end 
    
    def to_str
      "Action: Soap CreateTag"
    end
  end
end
 
if $0 == __FILE__
require "action/soap/login"
require "model/user"

user = Model::TARGETHOST.cUser('admin',Model::DEFAULTPASSWORD) 
testme = Action::Soap::Login.new(user) 
testme.run 
testme2 = Action::Soap::CreateTag.new("testme",4, user)
testme2.run
puts YAML.dump(testme2)
end