#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2013 Vmware Zimbra
#
# Part of the command class structure.  This is the interface to zmproxypurge command
#

if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
  $:.unshift(File.join('/','opt','qa','genesis')) #append genesis path
end
require "action/command"
require "action/block"
require "action/verify"
require "action/runcommand"
require "action/zmprov"
require "model"



module Action # :nodoc
  #
  # Perform zmproxypurge action.  This will invoke some zmproxypurge with some arguments

  #
  class ZMProxyPurge < Action::RunCommand

    #
    #  Create a ZMProxyPurge object.
    #

    def initialize(*arguments)
      super(File.join(ZIMBRAPATH,'bin','zmproxypurge'), ZIMBRAUSER, *arguments)
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
    # Unit test case for zmproxypurge object
    class ZMProxyPurgeTest < Test::Unit::TestCase
      def testRun
        testObject = Action::ZMProxyPurge.new
        testObject.run
        assert(testObject.response.include?('No accounts specified'))
      end
    end
  end
end


