#!/usr/bin/ruby -w
#
#<soap:Body>
# <BatchRequest xmlns="urn:zimbra" onerror="continue">
# <GetApptSummariesRequest xmlns="urn:zimbraMail" s="1130655600000" e="1134288000000" l="10" id="0"/>
# </BatchRequest>
#</soap:Body>
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end
require 'action/soap/command'  
require 'model/testbed' 
require 'net/http'
require "yaml"

module Action::Soap
  
  class GetApptSum < Action::Soap::Command
    
    @@gastemplate = @@template%['%s','%s', 
      '<SearchRequest xmlns="urn:zimbraMail" sortBy="dateAsc" types="appointment" calExpandInstStart="%s000" calExpandInstEnd="%s000"><query>inid:10</query></SearchRequest>']
      
    def initialize(user, startDate, endDate, host = Model::Host.new(Model::Servers.getServersRunning("mailbox").first),
                   port = 443)
      super()      
      @user = user  
      @host = host
      @port = port
      @startDate = startDate || Time.now
      @endDate = endDate || (@startDate + 30 * 60)
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
          dataOut = @@gastemplate%[@user.token, @user.sessionid, @startDate.to_i, @endDate.to_i]
          #dataOut = @@gastemplate%[@user.token, @user.sessionid, @endDate.to_i, @startDate.to_i]
          @response = x.post('/service/soap/', dataOut, {'Content-Type' => 'text/xml;charset=us-ascii',
              'SOAPAction' => ''} 
           )           
        }  
      end
    end 
    
    def to_str
      "Action: Soap Get Appointment Summary #{@startDate} #{@endDate}"
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
        @appointment = Action::Soap::CreateAppointment.new(@user, 'getappsum', 'this is for get appointment summary test')
        @appointment.run
        puts YAML.dump(@appointment)
      end
      
      def testDefault
        testme2 = Action::Soap::GetApptSum.new(@user, Time.now - 2 * 24 * 60 * 30, Time.now + 2 * 24 * 60 * 30)
        testme2.run
        puts YAML.dump(testme2)
      end
 
    end
  end 
end