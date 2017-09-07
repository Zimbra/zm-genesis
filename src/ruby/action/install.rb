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
# Part of the command class structure.  This implements install action
# 
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end
require 'action/command'
require 'action/zmcontrol'
require 'action/killuser'
require 'action/clean'
 
module Action # :nodoc
  #
  #  Perform install option at the current file
  #
  class Install < Action::Command
    #
    # Objection creation
    # bind untar object with specified +filename+
    def initialize(confFile = nil, changeDirectory = 'zcs')
      super()      
      @commandLine  =  "install.sh"
      @confFile = confFile
      @changeDirectory = changeDirectory
    end
     
    #
    # Execute untar action
    # filename is stored inside @@filename at object initilization time 
    def run
      super()  
      #shut down zimbra
      Action::ZMControl.new("stop").run      
      #kill dangling processes
      Action::KillUser.new.run #get rid of zimbra stuffs
      Action::KillUser.new('root','master').run #get rid of postfix
      # unmount virus directory
      `umount #{File.join(ZIMBRAPATH, 'amavisd', 'tmp')}`
      # zap zimbra directory
      Action::Clean.new(ZIMBRAPATH,true).run
      oldDir = Dir.getwd
      Dir.chdir(@changeDirectory)
      confFile = @confFile || @@run_env[CONFIG] #late binding
      invokeString = "#{File.join(Dir.getwd, @commandLine)} #{confFile}"
      result = `#{invokeString}`    
      Dir.chdir(oldDir)
      result
    end   
    
    def to_str
      confFile = @confFile || @@run_env[CONFIG] #late binding
      "Action:install conf:#{confFile}"
    end  
  end
    
  
end

if $0 == __FILE__
  require 'test/unit'  
  
  module Action
    # Unit test cases for Install
    class InstallTest < Test::Unit::TestCase     
      def testRun
        Dir::mkdir('zimbramail')
        testObject = Action::Install.new(File.join('..','conf','default.conf'))
        testObject.run
        Dir::delete('zimbramail')
      end
      
      def testTOS
        testObject = Action::Install.new
        puts testObject
      end
    end
  end
end
 
  

