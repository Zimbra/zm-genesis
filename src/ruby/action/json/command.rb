#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
#
#
if($0 == __FILE__)
  #$:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?ybur/,"").reverse; $:.unshift(File.join(mydata, 'ruby')) 
end

require 'net/https'
require 'json'

require 'action/command' 
 

 
module Action::Json

  class Command < Action::Command  
    
    def initialize(cname="Nop", host=Model::Host.new(Model::Servers.getServersRunning("mailbox").first),
                   port=443, cmode='https') 
      super()
      #for now cname=the request
      @host = host
      @port = port.to_i
      @request = cname
      @response = nil
      @mode = cmode
    end 
    
    def run
      #$DEBUG=1
      if(@request.user != nil)
        @host ||= @@run_env[MAILPORT]
        http = Net::HTTP.new(@host.to_s, @port) 
        http.use_ssl = true if @mode == 'https'
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        http.set_debug_output $stdout if $DEBUG    
        http.start { |x|
          @response = x.post(@request.uri,
                             @request.to_json, {'Content-Type' => 'text/xml;charset=us-ascii'})
        }  
        #@response
        @response.class == Net::HTTPOK ? [0, JSON::parse(@response.body)] : [@response.code, @response.body]
      end
    end 
    
    def result
      JSON::parse(@response.body)['Body'][@request.class.name.split(/::/).last.sub('Request', 'Response')]
    end
    
    def to_json(*a)
      {
      'json_class'   => self.class.name,
      'data'         => @request#.to_json
      }.to_json(*a) 
    end
    
    def self.json_create(o)
      new(*o['data'])
      #new
    end
  end
end

if $0 == __FILE__
  require 'test/unit'  
  include Action
  
   
    # Unit test cases for Proxy
    class CommandTest < Test::Unit::TestCase     
      def testNoArgument 
        testOne = Action::Json::Command.new
        assert(testOne.timeOut == 60)
      end      
    end   
end
 
    
     