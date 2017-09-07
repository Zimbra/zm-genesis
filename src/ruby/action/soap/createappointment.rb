#!/usr/bin/ruby -w
#
# CreateAppointment command
#
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end
require 'action/soap/command'  
require 'model/testbed' 
require 'net/http'
require 'uri'
require "yaml"

module Action::Soap
#<CreateAppointmentRequest xmlns="urn:zimbraMail">
# <m d="1131940683421">
#   <inv method="REQUEST" type="event" fb="F" transp="O" status="CONF" allDay="0" name="testme" loc="">
#       <s d="20051113T200000" tz="(GMT-08.00) Pacific Time (US & Canada) / Tijuana"/>
#       <e d="20051113T210000" tz="(GMT-08.00) Pacific Time (US & Canada) / Tijuana"/>
#     <or a="admin@qa04.liquidsys.com"/>
#   </inv>
#   <mp ct="text/plain">
#     <content>
#       this is just a test
#     </content>
#   </mp>
#   <su>
#     testme
#   </su>
# </m>
#</CreateAppointmentRequest>
  
  class CreateAppointment < Action::Soap::Command
    @@cappTemplate = @@template%['%s','%s','<CreateAppointmentRequest xmlns="urn:zimbraMail">'+ 
      '%s</CreateAppointmentRequest>']
      
    @@caMeetingTemplate = "<m d=\"%s\">\n%s\n</m>"
    
    @@caTimeZone = '(GMT-08.00) Pacific Time (US &amp; Canada) / Tijuana'
    
    @@caInvitationTemplate = '<inv><comp type="event" fb="B" transp="O" status="CONF" allDay="0" name="%s">'+"\n"+
      '<s tz="'+@@caTimeZone+'" d="%s"/>'+
      '<e tz="'+@@caTimeZone+'" d="%s"/>'+
      '<or a="%s"/>'+"\n"+
      '</comp></inv>'
      
    @@caContentTemplate = '<mp ct="text/plain">'+
      '<content>%s</content></mp>'
      
    @@caSummaryTemplate = '<su>%s</su>'    
    
 
    
    def initialize(user, title, note = nil, startDate = nil, endDate = nil,
                   host = Model::Host.new(Model::Servers.getServersRunning("mailbox").first), port = 443)
      super()       
      @user = user
      @host = host
      @port = port  
      @response = nil
      @startDate = startDate || Time.now
      @endDate = endDate || (@startDate + 60 * 30) # 30 mins in the future
      @title = title
      @note = note || ''
    end
    
    def run 
      dateFormat = '%Y%m%dT%H%M%S'
      if(@user != nil)
        @host ||= @@run_env[MAILPORT]
        http = Net::HTTP.new(@host.name, @port)
        http.use_ssl = true if @port == 443
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        http.set_debug_output $stdout if $DEBUG       
        http.start do |x|
          summary = @@caSummaryTemplate%[@title]
          content = @@caContentTemplate%[@note]           
          invitation = @@caInvitationTemplate%[@title, @startDate.strftime(dateFormat),
            @endDate.strftime(dateFormat), @user.name]
          meeting = @@caMeetingTemplate%[Time.now.to_i*1000, invitation+content+summary]  
          dataOut = @@cappTemplate%[@user.token, @user.sessionid, meeting] 
          @response = x.post('/service/soap/', dataOut, {'Content-Type' => 'text/xml;charset=us-ascii',
              'SOAPAction' => ''}) 
        end #http          
        class << @response
          attr :inid, true
        end
        if (@response.body =~ /<CreateAppointmentResponse.*invId="(.*?)"/m) 
          @response.inid = $1
        else
          @response.inid = nil
        end
      end 
    end 
    
    def to_str
      "Action: Soap CreatAppointment"
    end
  end
end
 
if $0 == __FILE__
require "action/soap/login"
require "model/user"

user = Model::TARGETHOST.cUser('admin',Model::DEFAULTPASSWORD) 
testme = Action::Soap::Login.new(user) 
testme.run 
testme2 = Action::Soap::CreateAppointment.new(user, 'testme', 'whatever')
testme2.run
puts YAML.dump(testme2)
end