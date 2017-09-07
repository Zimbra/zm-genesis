#!/usr/bin/ruby -w
#
# CreateContact command
#
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end
require 'action/soap/command'  
require 'model/testbed' 
require 'net/http'
require "yaml"

module Action::Soap
#     <CreateContactRequest xmlns="urn:zimbraMail">
#                <cn>
#                    <a n="firstName">First.${TIME}.${COUNTER}</a>
#                    <a n="lastName">Last.${TIME}.${COUNTER}</a>
#                    <a n="email">email.${TIME}.${COUNTER}@domain.com</a>
#                    <a n="company">${company.name}</a>
#                    <a n="fileAs">7</a>
#                </cn>     
#     </CreateContactRequest>
  
  class CreateContact < Action::Soap::Command
    @@cctTemplate = @@template%['%s','%s','<CreateContactRequest xmlns="urn:zimbraMail">'+
      '<cn>%s</cn></CreateContactRequest>']
      
 
    
    def initialize(user, information, host = Model::Host.new(Model::Servers.getServersRunning("mailbox").first),
                   port = 443)
      super()      
      @information = information
      @user = user
      @host = host
      @port = port  
      @response = nil
      @template = @@template%['%s','%s','<CreateContactRequest xmlns="urn:zimbraMail">'+
      '<cn>%s</cn></CreateContactRequest>']
    end
    
    def run
      if(@user != nil)
        @host ||= @@run_env[MAILPORT]
        http = Net::HTTP.new(@host.name, @port)
        http.use_ssl = true if @port == 443
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        http.set_debug_output $stdout if $DEBUG       
        http.start do |x|
          contact = @information.to_a.inject([]) do |acc, item|
            acc = acc << '<a n="%s">%s</a>'%item
          end.join('') 
          dataOut = @@cctTemplate%[@user.token, @user.sessionid, contact]
          @response = x.post('/service/soap/', dataOut, {'Content-Type' => 'text/xml;charset=us-ascii',
              'SOAPAction' => ''} 
           )           
        end #http  
        class << @response
          attr :cnid, true
        end
        if (@response.body =~ /<CreateContactResponse.*id="(.*?)"/m) 
          @response.cnid = $1 
        else
          @response.cnid = nil
        end
      end
    end 
    
    def to_str
      "Action: Soap CreateContact"
    end
  end
end
 
if $0 == __FILE__
require "action/soap/login"
require "model/user"

user = Model::TARGETHOST.cUser('admin',Model::DEFAULTPASSWORD) 
testme = Action::Soap::Login.new(user) 
testme.run 
testme2 = Action::Soap::CreateContact.new(user, { 'firstName' => 'bill', 'lastName' => 'joe'})
puts testme2.run
puts YAML.dump(testme2)
end