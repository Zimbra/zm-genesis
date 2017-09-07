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
# Part of the command class structure.  This is the interface to zmldapreplicatool command
#

if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end

require "action/command"
require "action/clean"
require "action/block"
require "action/verify"
require "action/runcommand"


module Action # :nodoc
  #
  # Perform zmldapreplicatool action.  This will invoke some zmldapreplicatool with some arguments

  #
  class ZMLdapreplicatool < Action::Command

    #
    #  Create a zmldapreplicatool object.
    #

    attr :label, true
    def initialize(*arguments)
      super()
      @runner = RunCommandOnLdap.new(File.join(ZIMBRAPATH,'libexec','zmldapreplicatool'), ZIMBRAUSER, *arguments)
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
    # Unit test case for zmldapreplicatool object
    class ZMLdapReplicaToolTest < Test::Unit::TestCase
      def testHelp
        testObject = ZMLdapreplicatool.new('-h')
        assert testObject.run[1].split(/\n/).select {|w| w =~ /#{Regexp.escape('zmldapreplicatool [-r RID] [-m masterURI] [-t critical|off]')}/}.length == 1
      end
    end
  end
end


