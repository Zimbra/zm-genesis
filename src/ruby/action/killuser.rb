#!/usr/bin/ruby -w
#
# = action/getbuild.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# Part of the command class structure.  This is the interface to zmcontrol command
#
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end
require 'action/system'
 
 
module Action # :nodoc

  #
  # Perform tomcat action.  This will invoke some tomcat with some argument
  # from http server
  #
  class KillUser < Action::Command
  
    #
    #  Create a KillUser object.
    #
    attr_reader :response
    
    def initialize(userName = ZIMBRAUSER, filter = nil) 
      super()
      @filter = nil
      @filter = Regexp.new(filter) if filter
      @pattern = Regexp.new('(\d+)')
      if(RUBY_PLATFORM =~ /win32/)
        super(File.join('c:','cygwin','bin','ps.exe'), 'root','-u', userName)
        @killProgram = File.join('c:','cygwin','bin','echo.exe')

      else
        super(File.join('','bin','ps'), 'root','-u', userName)      #-p to use effective user id
        @killProgram = File.join('','bin','kill') 
      end      
    end 
    
    def run
      counter = 0
      begin     
        super 
        if(@response)
          id_list = []
          @response.each_line { |curLine|
            next if (@filter  && (not @filter.match(curLine)))
            id_list.push << $1 if(@pattern.match(curLine))            
          }         
          if(counter > 12) # one min, no more nice guy
            Action::System.new(@killProgram, 'root', '-9', *id_list).run if(id_list.length > 0)
          else
            Action::System.new(@killProgram, 'root', *id_list).run if(id_list.length > 0)
          end
        end
        sleep 5 # five second
        counter += 1
      end until (id_list.length == 0) || (counter > 60)      
    end
    
    def to_str
      "Action:KillUser method #{@userName}"
    end  
  end 
   
end

if $0 == __FILE__
  require 'test/unit'
  module Action
    #
    # Unit test case for KillUser object
    class KillUserTest < Test::Unit::TestCase
      def testRun
        testObject = Action::KillUser.new('bhwang','hi')
        testObject.run
        assert(testObject.exitstatus == 0, "fail path")
      end
      
      def testTOS
        testObject = Action::KillUser.new
        puts testObject
      end
    end
  end
end


