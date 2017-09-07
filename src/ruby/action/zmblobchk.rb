#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2008 Yahoo Inc.
#
#
# Part of the command class structure.  This is the interface to zmblobchk command
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
  # Perform ZMBlobchk action.  This will invoke some ZMBlobchk with some arguments

  #
  class ZMBlobchk < Action::Command

    #
    #  Create a ZMBlobchk object.
    #

    attr :label, true
    def initialize(*arguments)
      super()
      @runner = RunCommandOnMailbox.new(File.join(ZIMBRAPATH,'bin','zmblobchk'), ZIMBRAUSER, *arguments)
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
    # Unit test case for ZMBlobchk object
    class ZMBlobchkTest < Test::Unit::TestCase

      def testTOS
#        testObject = Action::ZMBlobchk.new('ca yes')
#       assert(testObject.to_str.include?("ca yes"))
      end
#
    end
  end
end


