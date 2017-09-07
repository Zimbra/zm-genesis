#!/usr/bin/ruby -w
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end
require 'action/soap/command'  
require 'model/testbed' 
require 'net/http'
require "yaml"

module Action::Soap
  
  class GetMessage < Action::Soap::Command
    
    @@gmTemplate = @@template%['%s','%s','<GetMsgRequest xmlns="urn:zimbraMail">'+
      '<m id="%s" read="1" html="1"/></GetMsgRequest>']
      
    def initialize(user, mid, host = Model::Host.new(Model::Servers.getServersRunning("mailbox").first), port = 443)
      super()      
      @user = user
      @mid = mid
      @host = host
      @port = port  
      @response = nil       
    end
    
    def run
      if(@user != nil)
        @host ||= @@run_env[MAILPORT]
        http = Net::HTTP.new(@host.name, @port)
        http.use_ssl = true if @port == 443
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        http.set_debug_output $stdout if $DEBUG       
        http.start { |x|
          dataOut = @@gmTemplate%[@user.token, @user.sessionid, @mid]
          @response = x.post('/service/soap/', dataOut, {'Content-Type' => 'text/xml;charset=us-ascii',
              'SOAPAction' => ''} 
           )           
        }  
      end
    end 
    
    def to_str
      "Action: Soap GetMsg"
    end
  end
end
 
if $0 == __FILE__
require "action/soap/login"
require "action/soap/createappointment"
require "model/user"
require 'test/unit'  
  
  module Action::Soap
    # Unit test cases for FileDelta
    class GetContactTest < Test::Unit::TestCase  
      def setup
        @user = Model::TARGETHOST.cUser('admin', Model::DEFAULTPASSWORD)
        Action::Soap::Login.new(@user).run
        @appointment = Action::Soap::CreateAppointment.new(@user, 'getmsttest', 'this is for getmsg test')
        @appointment.run
      end
      
      def testDefault
        testme2 = Action::Soap::GetMessage.new(@user, @appointment.response.inid)
        testme2.run
        puts YAML.dump(testme2)
      end
 
    end
  end 
end