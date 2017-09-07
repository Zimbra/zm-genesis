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
# Part of the command class structure.  This is the interface to zmproxyconfgen command
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
  # Perform ZMProxyconfgen action.  This will invoke some ZMProxyconfgen with some arguments

  #
  class ZMProxyconfgen < Action::Command

    #
    #  Create a ZMProxyconfgen object.
    #

    attr :label, true
    def initialize(*arguments)
      super()
      @runner = RunCommandOnProxy.new(File.join(ZIMBRAPATH,'libexec','zmproxyconfgen'), ZIMBRAUSER, *arguments)
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
    # Unit test case for ZMProxyconfgen object
    class ZMProxyconfgenTest < Test::Unit::TestCase

      def testTOS
#        testObject = Action::ZMProxyconfgen.new('ca yes')
#       assert(testObject.to_str.include?("ca yes"))
      end
#
    end
  end
end


