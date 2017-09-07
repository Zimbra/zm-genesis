#!/usr/bin/ruby -w
#
# = action/filedelta.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# Part of the command class structure.  This implements delta fetching logic.
# This is rather simplistic approach.  It will not follow renamed file
# 
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end
 
require 'action/command'
require 'action/proxy'
require 'yaml'
 
module Action # :nodoc
  #
  #  Perform file monitoring
  #
  class FileDelta < Action::Command
    #
    # Objection creation
    # bind FileDelta object with specified +filename+.  It is defaulted to ZIMBRAPATH/log/zimbra.log

    attr_reader :data, :fileName
    def initialize(fileName = nil)
      super()
      @fileName = fileName || File.join(ZIMBRAPATH,'log','zimbra.log')
      @curpos = 0 
      @marker = 0
      @proxy = nil
      @data = nil
    end
     
    #
    # Execution engine
    #  
    def run
      super
      set     
    end
    
    
    #
    #  Generate proxy object that will run fetch
    #
    def delta 
      if(@proxy == nil)
        @proxy = Action::Proxy.new(self.method('fetch'))                          
      end
      @proxy
    end
    
    #
    # Remember file size and creation date
    #
    def set(env=nil)   
      return unless File.exist?(@fileName)
      
      begin
        stat = File.stat(@fileName) 
        @curpos = stat.size
        @marker = mark(stat) 
      rescue Errno::ENOENT 
        @curpos = 0    
        @marker = 0   
      end 
    end
    
    def mark(x)
      if(RUBY_PLATFORM =~ /mswin32/)
        x.ctime
      else
        x.ino
      end
    end
    
    #
    # Fetch delta data 
    #
    def fetch  
      @data = nil           
      
      return unless File.exist?(@fileName)
      begin
        stat = File.stat(@fileName)
        nowpos = stat.size
        nowmarker = mark(stat)         
        if(@marker == nowmarker)  
          case (@curpos <=> nowpos)
            when -1 #delta detected 
              @data = IO.read(@fileName, (nowpos-@curpos+1), @curpos)             
            when +1 #file is shorten, whole file
              @data = IO.read(@fileName)        
           end
        else # whole new file
          (@data = IO.read(@fileName)) if (nowpos != 0) #partial recovery
        end
      rescue => weird 
        @data = weird.message
      end 
      if not @data.nil?
        class << @data
          def inspect 
           YAML.dump(self)
          end
        end
      end
      @data
    end
    
    def to_str
      "Action:FileDelta file:#{@fileName}"
    end  
  end    
  
end

if $0 == __FILE__
  require 'test/unit'  
  
  module Action
    # Unit test cases for FileDelta
    class FileDeltaTest < Test::Unit::TestCase     
      def testNothingNew
        Dir::mkdir('filedelta') unless File.exist?('filedelta')
        fileName = File.join(Dir.pwd, 'filedelta','testfileone')
        f = File.new(fileName, 'w')
        
        testObject = Action::FileDelta.new(fileName)        
        f.close
        testObject.run

        data = testObject.fetch        
        File.unlink(fileName)
        Dir::delete('filedelta')
        assert(data == nil,"empty check failure")
      end
      
      def testAddition
        Dir::mkdir('filedelta') unless File.exist?('filedelta')        
        fileName = File.join(Dir.pwd, 'filedelta','testfileone.txt') 
        File.unlink(fileName) if File.exist?(fileName)
        
        testObject = Action::FileDelta.new(fileName)  
        f = File.new(fileName, 'w')
        f.write("this is before")    
        f.close
        testObject.run
        f = File.new(fileName, 'a')
        f.write("this is after")
        f.close
        data = testObject.fetch  
        File.unlink(fileName)
        Dir::delete('filedelta') 
        assert(data == "this is after","addition data check")
      end
      
      def testDelta
        Dir::mkdir('filedelta') unless File.exist?('filedelta')        
        fileName = File.join(Dir.pwd, 'filedelta','testfileone.txt') 
        File.unlink(fileName) if File.exist?(fileName)
        
        testObject = Action::FileDelta.new(fileName)  
        caller = testObject.delta
        f = File.new(fileName, 'w')
        f.write("this is before")    
        f.close
        testObject.run
        f = File.new(fileName, 'a')
        f.write("this is after")
        f.close
        caller.run
        data = testObject.data
        File.unlink(fileName)
        Dir::delete('filedelta') 
        assert(data == "this is after","addition data check")
      end
      
      def testNewFile
        Dir::mkdir('filedelta') unless File.exist?('filedelta')        
        fileName = File.join(Dir.pwd, 'filedelta','testfileone.txt') 
        File.unlink(fileName) if File.exist?(fileName)
        
        testObject = Action::FileDelta.new(fileName) 
        f = File.new(fileName, 'w')
        f.write("this is before")    
        f.close
        testObject.run
        File.unlink(fileName)
        f = File.new(fileName, 'w')
        f.write("this is after")
        f.close
        data = testObject.fetch 
        File.unlink(fileName)
        Dir::delete('filedelta') 
        assert(data == "this is after","new file test")
      end
      
      def testTOS
        testObject = Action::FileDelta.new
        assert(testObject.class == Action::FileDelta)
      end

       def testTimeOut
          testObject = Action::FileDelta.new
          assert(testObject.timeOut == 60)
       end
    end
  end
end
