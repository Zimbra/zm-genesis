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
  
  class CreateFolder < Action::Soap::Command
    
    def initialize(user, folderName, baseFolderId, host = Model::Host.new(Model::Servers.getServersRunning("mailbox").first),
                   port = 443)
      super()      
      @user = user
      @host = host
      @port = port.to_i
      @response = nil
      @folderName = folderName
      @baseFolderId = baseFolderId
      @template = @@template%['%s','%s','<CreateFolderRequest xmlns="urn:zimbraMail">'+
      ' <folder name="%s" l="%s"/></CreateFolderRequest>']
    end
    
    def run
      if(@user != nil)
        @host ||= @@run_env[MAILPORT]
        http = Net::HTTP.new(@host.name, @port)  
        http.use_ssl = true if @port == 443
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        http.set_debug_output $stdout if $DEBUG       
        http.start { |x|
          dataOut = @template%[@user.token, @user.sessionid, @folderName, @baseFolderId]
          @response = x.post('/service/soap/', dataOut, {'Content-Type' => 'text/xml;charset=us-ascii',
              'SOAPAction' => ''} 
           )           
        }  
      end
    end 
    
    def to_str
      "Action: Soap CreateFolder"
    end
  end
end
 
if $0 == __FILE__
require "action/soap/login"
require "model/user"

user = Model::TARGETHOST.cUser('admin',Model::DEFAULTPASSWORD) 
testme = Action::Soap::Login.new(user) 
testme.run 
testme2 = Action::Soap::CreateFolder.new(user,"testme",1)
testme2.run
puts YAML.dump(testme2)
end