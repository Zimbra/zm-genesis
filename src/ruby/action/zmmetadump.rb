#!/bin/env ruby -w
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2008 Yahoo
#
# Part of the command class structure, This is the interface to zmmetadump commands
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
  # Perform zmmetadump action
  #
  class ZMMetadump < Action::RunCommandOnMailbox

    #
    #  Create a zmmetadump object
    #

    def initialize(*arguments)
      super(File.join(ZIMBRAPATH,'bin','zmmetadump'), ZIMBRAUSER, *arguments)
    end
  end
end

if $0 == __FILE__
  require 'test/unit'
  module Action
    #
    # Unit test case for ZMMetadump object
    class ZMMetadumpTest < Test::Unit::TestCase
      def testRun
        testObject = Action::ZMMetadump.new('-h')
        testObject.run
        puts testObject.response
        puts testObject.response.include?("help")
      end

    end
  end
end


