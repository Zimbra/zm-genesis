#!/usr/bin/ruby -w
#
# = engine/simple.rb
#
# Copyright (c) 2005 Zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# Simple test case engine, run one test case
# 
require 'log4r'
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end

module Engine

  class Simple
  
    def initialize(testCase = nil, filter = true)
      @testCase = testCase
      @filter = filter
      @logger = Log4r::Logger.new 'enginelog' 
      p = Log4r::PatternFormatter.new(:pattern => "[%l][%d] %M") 
      @logger.outputters = Log4r::StdoutOutputter.new 'console', :formatter => p 
    end
    
    def dump(mobject)
      ddump = false
      begin
        mobject.nodump
      rescue NoMethodError
        ddump = true
      end
      if ddump
        @logger.debug YAML.dump(mobject)
        @logger.debug "*"*80  
      end
    end
    
    def run(testCase = nil)    
    
      @testCase = testCase unless (testCase == nil)        
      
      # Execution
      @testCase.action.flatten.compact.each do |x|
        begin
         @logger.info x.class.to_s
         x.run
        rescue Timeout::Error   
          class << x
            attr :check, true
            attr :pass, true  
            attr :response, true
          end   
          x.check = true
          x.pass = false     
          x.response = 'Step time out #{x.timeOut}'
        rescue
          class << x
            attr :check, true
            attr :pass, true 
            attr :response, true      
            attr :trace, true         
          end
          x.check = true
          x.pass = false
          x.response = $!         
          x.trace =  $!.backtrace 
        end
      end 
   
      # Result processing
      result = @testCase.action.flatten.compact.map do |x|
        begin     
          if(@filter && begin x.check rescue false end && !x.pass)                   
            self.dump(x)
            x.pass     
          elsif(!@filter)     
            self.dump(x)
            nil
          end #if    
        rescue NoMethodError
         
        end
      end.compact # testcase

      if block_given?
        yield result
      else
        result
      end       
    end #run
  end #class 
end #module

if($0 == __FILE__)
  require 'test/unit' 
  
  include Engine
   
  class SimpleTest < Test::Unit::TestCase
  
    def testInit
      testOne = Simple.new
      assert(testOne.class == Simple, "Object creation test")
    end
  end
end