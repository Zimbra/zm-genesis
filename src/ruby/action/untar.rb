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
# Part of the command class structure.  This implements untar action
# 
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end
require 'action/command'
require 'action/clean'
 

module Action # :nodoc
  #
  #  Perform untar option at the current file
  #
  class Untar < Action::System
    #
    # Objection creation
    # bind untar object with specified +filename+
    def initialize(filename = 'zcs.tgz', toplevel = 'zcs')
      super("tar -xvzf", 'root', filename)
      @filename = filename 
      @toplevel = toplevel
    end
     
    #
    # Execute untar action
    # filename is stored inside @@filename at object initilization time 
    def run 
      Action::Clean.new(@toplevel).run if (File::exist?(@toplevel))  
      super
    end    
    
    def to_str
      "Action:untar file:#{@filename} toplevel:#{@toplevel}"
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
          testObject = Action::Untar.new(File::join('src','ruby','action','testdata','cookie.tgz'),"Cookies")
          testObject.run
          testDir = "Cookies"
          Dir.foreach(testDir) { |x|        
            File.delete(File::join(testDir,x)) if not x.match('^\.\.{0,1}$')
          } 
          Dir.delete(testDir)
        end
        
        def testTOS
          testObject = Action::Untar.new
          puts testObject
        end        
          
    end
  end
end

