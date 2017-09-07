#!/usr/bin/ruby -w
#
# = action/untar.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# Part of the command class structure.  This implements mail data model
# 
 

module Model # :nodoc
  
  class Mail
    #
    # Objection creation
    # bind untar object with specified +filename+
    @@index = 0
    @@preTime = Time.now
    SEPERATOR = "\n"
    attr_reader :to
    
     

    def initialize(from = nil, to = nil, subject = nil, body = '')
      @from = from
      @to = to
      @subject = subject
       
      @header = [createString("From: %s", @from), 
                 createString("To: %s", @to),
                 createString("Subject: %s", @subject),
                 ].compact.join(SEPERATOR)
      @body = body 
      
      yield self if block_given? 
    end   
    
    def createString(template, data)
      if(data == nil)
        nil
      else
        template % data
      end
    end
    
    def to_s      
      @@index = @@index + 1
      nowTime = Time.now
      if(nowTime  != @@preTime)
        @@preTime = nowTime
        @@index = 1
      end
      timestamp = "%10.10f" % nowTime.to_f
      @header << "\n" << "X-Zimbra-Test-Id: #{timestamp} #{@@index}#{SEPERATOR}#{SEPERATOR}" << @body      
    end  
  end
    
  
end

if $0 == __FILE__
  require 'test/unit'  
  
  module Model
    # Unit test cases for SendMail
    class MailTest < Test::Unit::TestCase     
      def testRun         
        testObject = Model::Mail.new('from me','to you')        
        puts testObject        
        sleep 1.2
        puts testObject   
      end
      
      def testRunTwo
        Model::Mail.new('from me','to you') do |testObject|
          puts testObject
        end 
      end
    end
  end
end
 
  

