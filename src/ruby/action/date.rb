#!/bin/env ruby -w
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2008 Yahoo
#
# Part of the command class structure, This is the interface to Date class
#

if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end
require 'action/runcommand'
require 'action/stafsystem'
require 'tempfile'
require 'model/testbed'


module Action # :nodoc

  #
  # Perform date action
  #
class Date < Action::Command

    #
    #  Create a Date object.
    #


    attr :timestamp,true
    def initialize(*arguments)
      super()
      @runner = RunCommand.new('/bin/date','root', *arguments)
      @timestamp = 'null'
      self.timeOut = 2400 #timeout to 40 minutes
    end

    def run
     super
     @runner.run
      if(self.exitstatus == 0 && self.response != nil)
        begin
          @timestamp = self.response.match(/.*([0-9]{14}).*/)[1].to_s
         rescue
          @timestamp = ''
        end
      end
      [self.exitstatus, self.response, @timestamp]
    end

    def to_str
      @runner.to_str
    end

    def method_missing(name, *args)
      @runner.__send__(name, *args)
    end

    def ctimestamp
      return self.method("timestamp")

    end

  end
end

if $0 == __FILE__
  require 'test/unit'
  module Action
    #
    # Unit test case for Date object
    class DateTest < Test::Unit::TestCase
      def testRun
        testObject = Action::Date.new('--help')
        testObject.run
        puts testObject.response

      end

    end
  end
end


