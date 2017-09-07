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
# Part of the command class structure.  This is the interface to zmdisklog command
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
  # Perform ZMDisklog action.  This will invoke some ZMDisklog with some arguments

  #
  class ZMDisklog < Action::Command

    #
    #  Create a ZMDisklog object.
    #

    attr :label, true
    def initialize(*arguments)
      super()
      @runner = RunCommand.new(File.join(ZIMBRAPATH,'libexec','zmdisklog'), ZIMBRAUSER, *arguments)
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
    # Unit test case for ZMDisklog object
    class ZMDisklogTest < Test::Unit::TestCase
      def testTOS
      end
    end
  end
end


