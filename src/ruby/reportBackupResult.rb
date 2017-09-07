#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
#
#
# This script will pull email information from dogfood account and report backup find
#
# 2008 Yahoo
require 'getoptlong'
require 'test/unit'
require 'yaml'

module Enumerable
  def foldr(o, m = nil)
    reverse.inject(m) {|m, i| m ? i.send(o, m) : i}
  end

  def foldl(o, m = nil)
    inject(m) {|m, i| m ? m.send(o, i) : i}
  end
end

module ReportBackup
  
  # This singleton contains bunch of strings.  All the string are in the form of either array of strings or string
  StringTable = Object.new
  class << StringTable 
    def helpMessage
      [
      'Report Dogfood Test Result',
      '-h help Message',
      '-s server',
      '-i iso']
    end   
  end 
  
  # Test cases for stringTable
  class TC_InputProcessor < Test::Unit::TestCase
    
    #make sure all methods with s_ prefix either return with string or string array
    def test_methods 
      [StringTable, Object.new].map {|x| x.methods}.foldl(:-).each do |z| 
        y = StringTable.send(z) 
        checkResult, errorMessage = case true
          when (y.kind_of? String) then
          [true, nil]
          when (y.kind_of? Array) then
          if y.all? {|z| z.instance_of? String } then
            [true, nil] 
          else
            [false, "Method #{z} #{y.inspect} does not contain all the strings"]
          end
        else
          [false, "Method #{z} returns unknown class #{y.class}"]
        end
        assert(checkResult, errorMessage)
      end 
    end
  end 
  
  # This class processes input options and store them as set of attributes
  class InputProcessor
    
    # if test is toggled
    attr :test, true
    # if help is toggled
    attr :help, true
    
    # initialize internal state variables
    def initialize 
      self.help = false
    end
    
    # return array of options
    def getOptions
      [
      ['-h', GetoptLong::NO_ARGUMENT] 
      ]
    end 
    
    # ARGV processor
    def getSetting 
      GetoptLong.new(*getOptions).each do | opt, arg|
        case opt
          when '-h' then
          help = true 
        end
      end 
    end
    
  end 
  # InputProcessor Test cases
  class TC_InputProcessor < Test::Unit::TestCase
    
    #Test initialization function
    def test_initialize
      testMe = InputProcessor.new
      assert(testMe.help == false, "Help attribute is not false")
      assert_kind_of InputProcessor, testMe, "InputProcessor initialization error" 
    end
    
    #Test getOptions make sure the datastructure being generated is correct
    def test_getOptions
      testMe = InputProcessor.new
      assert_instance_of Array, testMe.getOptions, "getOption does not return array class" 
      testMe.getOptions.all? do |x|
        assert(x.size == 2, "Illegal data #{x.inspect} data size mismatch")
        assert_kind_of String, x.first, "First element #{x.first.inspect} is not kind of String"
        assert_kind_of Fixnum, x.last, "Last element #{x.last.inspect} is not kind of Fixnum"
      end 
    end
  end
  
end
