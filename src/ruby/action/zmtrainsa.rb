#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2006 Zimbra
#
#
# Part of the command class structure.  This is the interface to zmtrainsa command
#
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end
require "action/command"
require "action/clean"
require "action/block"
require "action/verify"
require "action/runcommand"
require "action/waitqueue"
require "action/zmprov"
require "model"
require 'net/smtp'



module Action # :nodoc
  #
  # Perform ZMTrainsa action.  This will invoke some ZMTrainsa with some arguments

  #
  class ZMTrainsa < Action::Command

    #
    #  Create a ZMTrainsa object.
    #

    attr :label, true
    def initialize(*arguments)
      super()
      @runner = RunCommandOnAntispam.new(File.join(ZIMBRAPATH,'bin','zmtrainsa'), ZIMBRAUSER, *arguments)
      @label = ''
      self.timeOut = 2400 #timeout to 40 minutes
    end

    def run
      @runner.run
    end

    def to_str
      @runner.to_str
    end

    def method_missing(name, *args)
      @runner.__send__(name, *args)
    end
  end
end

if $0 == __FILE__
  require 'test/unit'
  module Action
    #
    # Unit test case for ZMTrainsa object
    class ZMTrainsaTest < Test::Unit::TestCase

      def testTOS
#        testObject = Action::ZMTrainsa.new('ca yes')
#       assert(testObject.to_str.include?("ca yes"))
      end
#
    end
  end
end


