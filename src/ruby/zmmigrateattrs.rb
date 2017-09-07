#!/bin/env ruby
#
# $File: //depot/zimbra/JUDASPRIEST/ZimbraQA/src/ruby/action/zmmigrateattrs.rb $
# $DateTime: 2016/11/22 00:10:55 $
#
# $Revision: #2 $
# $Author: rvyawahare $
#
# 2011 Vmware Zimbra
#
# Part of the command class structure.  This is the interface to zmmigrateattrs command
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
  # Perform zmmigrateattrs action.  This will invoke some zmmigrateattrs with some arguments

  #
  class ZMmigrateattrs < Action::Command

    #
    #  Create a zmmigrateattrs object.
    #

    attr :label, true
    def initialize(*arguments)
      super()
      @runner = RunCommand.new(File.join(ZIMBRAPATH,'bin','zmmigrateattrs'), ZIMBRAUSER, *arguments)
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
    # Unit test case for zmmigrateattrs object
    class ZMmigrateattrs < Test::Unit::TestCase
      def testTOS
      end
    end
  end
end
