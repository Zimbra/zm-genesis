#!/bin/env ruby -w
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
#  2009 Zimbra, Inc.
#
# Part of the command class structure, This is the interface to zmzimletctl commands
#

if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end
require 'action/runcommand'
require 'action/stafsystem'
require 'tempfile'
require 'model/testbed'


module Action # :nodoc

  #
  # Perform zmzimletctl action
  #
  class ZMZimlet < Action::RunCommandOnMailbox

    #
    #  Create a zmzimlet object
    #

    def initialize(*arguments)
      super(File.join(ZIMBRAPATH,'bin','zmzimletctl'), ZIMBRAUSER, *arguments)
    end
  end
end

if $0 == __FILE__
  require 'test/unit'
  module Action
    #
    # Unit test case for ZMZimlet object
    class ZMZimletTest < Test::Unit::TestCase
      def testRun
        testObject = Action::ZMZimlet.new('-h')
        testObject.run
        puts testObject.response
        puts testObject.response.include?("help")
      end

    end
  end
end


