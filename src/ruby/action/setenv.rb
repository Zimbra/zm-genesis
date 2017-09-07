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
# Part of the command class structure.  This implements enviornment set action
# 
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end
require 'action/command'
 

module Action # :nodoc
  #
  #  Perform setenv logic.  This manipulate global run enviorment data
  #
  class Setenv < Action::Command
    #
    # Objection creation
    # bind setenv object with particular name value pair
    def initialize(name = nil, value = nil)
      super()
      @name = name
      @value = value 
    end
     
    #
    # Execute setenv action
    # set system enviornment with some name value pair
    def run()
      super()       
      @@run_env[@name] = @value       
    end    
    
    def to_str
      "Action:setenv name #{name} value #{value}"
    end   
  end  
end
 
if $0 == __FILE__
  require 'test/unit'
  
  module Action  
    # Unit test cases for Untar
    class UntarTest < Test::Unit::TestCase
    
        # Basic execution, the test data is testdata/cookie.tgz"     
        def testRun()
          testObject = Action::Setenv.new(Action::Command::CONFIG,"hithere")
          testObject.run
          assert(Action::Command.run_env[Action::Command::CONFIG] == 'hithere','enviroment setting')
        end           
    end
  end
end

