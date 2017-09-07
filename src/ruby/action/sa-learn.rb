#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2009 Yahoo
#
# Part of the command class structure.  This is the interface to sa-learn command
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
  # Perform SALearn action.  This will invoke some SALearn with some arguments

  #
  class SALearn < Action::Command

    #
    #  Create a SALearn object.
    #

    attr :label, true
    def initialize(*arguments)
      super()
      @runner = RunCommandOnMta.new(File.join(ZIMBRACOMMON,'bin','sa-learn'), ZIMBRAUSER, *arguments)
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
    # Unit test case for SALearn object
    class SALearnTest < Test::Unit::TestCase
      def testTOS
      end
    end
  end
end


