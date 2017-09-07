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
require 'action/setenv'
 

module Action # :nodoc
  #
  #  Perform action of setting config file name into test enviorment global table
  #
  class SetConfig < Action::Setenv
    #
    # Objection creation
    # bind setconfig object to particular file name
    def initialize(fileName = File::join('conf','zimbra.conf'))
      super(CONFIG,nil)
      @fileName = fileName 
    end
     
    #
    # Execute set configuration option action
    # filename is stored inside @@filename at object initilization time 
    def run()
      getdirname = File.expand_path(File.join(File.dirname(__FILE__),'..'))
      @value = File::join(getdirname, @fileName)     
      super()
    end    
    
    def to_str
      "Action:setconfiguration fileName #{@fileName}"
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
          testObject = Action::SetConfig.new
          testObject.run
          puts Action::Command.run_env[Action::Command::CONFIG]
          #assert(Action::Command.run_env[Action::Command::CONFIG] == 'hithere','enviroment setting')
        end           
    end
  end
end

