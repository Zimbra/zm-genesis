#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# Part of the command class structure.  This implements sendmail action
# 
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end
 
require 'action/command' 
require 'model/testbed'
require 'net/smtp'

module Action # :nodoc
  #
  #  Perform sendmail action
  #
  class SendMail < Action::Command
    #
    # Objection creation
    # bind sendmail object to arguments
    # from address is fixed to genesis@test.qa.zimbra.com
    
    attr :exitstatus, true
    attr :error, true
    
    def initialize(to = nil, msg = nil, from = 'genesis@test.qa.zimbra.com', server = Model::Servers.getServersRunning("mta").first)
      super()
      @from = from
      @to = to
      @server = server 
      @msg = msg
    end

    #
    # Execute sendmail action
    #  
    def run()
      super()  
      Net::SMTP.start(@server, 25) do |smtp|         
        begin
          smtp.send_message @msg, @from, @to
          @exitstatus = 0
          @error = ''
        rescue
          @exitstatus = 1
          @error = $!
        end
      end      
      [@exitstatus, @error]
    end   
    
    def to_str   
      "Action:SendMail #{@from} #{@to}"
    end  
  end
    
  
end

if $0 == __FILE__
  require 'test/unit'  
  
  module Action
    # Unit test cases for SendMail
    class SendMailTest < Test::Unit::TestCase     
      def testRun         
        testObject = Action::SendMail.new('admin@'+Model::QA04, IO.readlines('c:\\zimbra.log'), Model::QA04)       
        testObject.run
      end
      
      def testTOS
        testObject = Action::SendMail.new
        puts testObject
      end
    end
  end
end
 
  

