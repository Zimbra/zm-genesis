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
# Part of the command class structure, This is the interface to zmlmtpinject commands
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
  # Perform zmlmtpinject action
  #
  class ZMLmtpinject < Action::RunCommandOnMailbox

    #
    #  Create a zmlmtpinject object
    #

    def initialize(*arguments)
      super(File.join(ZIMBRAPATH,'bin','zmlmtpinject'), ZIMBRAUSER, *arguments)
    end
  end
end

if $0 == __FILE__
  require 'test/unit'
  module Action
    #
    # Unit test case for ZMLmtpinject object
    class ZMLmtpinjectTest < Test::Unit::TestCase
      def testRun
        testObject = Action::ZMLmtpinject.new('-h')
        testObject.run
        puts testObject.response
        puts testObject.response.include?("help")
      end

    end
  end
end


