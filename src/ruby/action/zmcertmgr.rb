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
# Part of the command class structure, This is the interface to zmcertmgr commands
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
  # Perform zmcertmgr action
  #
  class ZMCertmgr < Action::RunCommand

    #
    #  Create a zmcertmgr object
    #

    def initialize(*arguments)
      super(File.join(ZIMBRAPATH,'bin','zmcertmgr'), 'zimbra', *arguments)
    end
  end
end

if $0 == __FILE__
  require 'test/unit'
  module Action
    #
    # Unit test case for ZMCertmgr object
    class ZMCertmgrTest < Test::Unit::TestCase
      def testRun
        testObject = Action::ZMCertmgr.new('-h')
        testObject.run
        puts testObject.response
        puts testObject.response.include?("help")
      end

    end
  end
end


