#!/usr/bin/ruby -w
#
# getcontact soap command
#
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end
require 'action/soap/command'  
require 'model/testbed' 
require 'net/http'
require "yaml"

module Action::Soap
  
  class GetContact < Action::Soap::Command
    @@gcTemplate = @@template%['%s','%s','<GetContactsRequest xmlns="urn:zimbraMail">'+
    '%s</GetContactsRequest>']
    
    def initialize(user = nil, filter = nil, host = Model::Host.new(Model::Servers.getServersRunning("mailbox").first),
                   port = 443)
      super()      
      @user = user
      @host = host
      @port = port  
      @filter = filter || {}
      @response = nil       
    end
    
    def run
      if(@user != nil)
        @host ||= @@run_env[MAILPORT]
        http = Net::HTTP.new(@host.name, @port)
        http.use_ssl = true if @port == 443
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        http.set_debug_output $stdouts if $DEBUG
        http.start { |x|
          if(@filter.size > 0)
            contact = @filter.to_a.inject([]) do |acc, item|
              acc = acc << '<a n="%s">%s</a>'%item
            end.join('')
            if(@filter.has_key?('id'))
              contact = '<cn>'+contact+'</cn>'
            end
          else
            contact = ''
          end 
          dataOut = @@gcTemplate%[@user.token, @user.sessionid, contact]
          @response = x.post('/service/soap/', dataOut, {'Content-Type' => 'text/xml;charset=us-ascii',
              'SOAPAction' => ''} 
           )           
        }  
      end
    end 
    
    def to_str
      "Action: Soap GetContact"
    end
  end
end
 
if $0 == __FILE__
require "action/soap/login"
require "model/user"
require 'test/unit'  
  
  module Action::Soap
    # Unit test cases for FileDelta
    class GetContactTest < Test::Unit::TestCase  
      def setup
        @user = Model::TARGETHOST.cUser('admin', Model::DEFAULTPASSWORD)
        Action::Soap::Login.new(@user).run
      end
      
      def testDefault
        testme2 = Action::Soap::GetContact.new(@user)
        testme2.run
        puts YAML.dump(testme2)
      end
      
      def testFilter
        testme = Action::Soap::GetContact.new(@user, {'id' => '258'})
        testme.run
        puts YAML.dump(testme)        
      end
    end
  end
 
end