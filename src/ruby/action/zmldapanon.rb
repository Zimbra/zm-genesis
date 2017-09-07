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
# Part of the command class structure.  This is the interface to zmldapanon command
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
  # Perform zmldapanon action.  This will invoke some zmldapanon with some arguments

  #
  class ZMLdapanon < Action::Command

    #
    #  Create a zmldapanon object.
    #

    attr :label, true
    def initialize(*arguments)
      super()
      @runner = RunCommandOnLdap.new(File.join(ZIMBRAPATH,'libexec','zmldapanon'), ZIMBRAUSER, *arguments)
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
    # Unit test case for zmldapanon object
    class ZMSoapTest < Test::Unit::TestCase
      def testTOS
      end
    end
  end
end


