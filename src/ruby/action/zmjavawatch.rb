#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2011 Vmware Zimbra
#
# Part of the command class structure.  This is the interface to zmjavawatch command
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
  # Perform zmjavawatch action.  This will invoke some zmjavawatch with some arguments

  #
  class ZMJavawatch < Action::Command

    #
    #  Create a zmjavawatch object.
    #

    attr :label, true
    def initialize(*arguments)
      super()
      unless arguments.last.is_a?(Model::Host)
        arguments << Model::Host.new(Model::Servers.getServersRunning("mailbox").first)
      end      
      @runner = RunCommand.new(File.join(ZIMBRAPATH,'libexec','zmjavawatch'), ZIMBRAUSER, *arguments)
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
    # Unit test case for zmjavawatch object
    class ZMSoapTest < Test::Unit::TestCase
      def testTOS
      end
    end
  end
end


