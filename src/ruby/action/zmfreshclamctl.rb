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
# Part of the command class structure.  This is the interface to zm*ctl commands
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
  # Perform Zmamavisd action.
  #
  class ZMFreshclamctl < Action::RunCommandOnMta

    #
    #  Create a Zmamavisd object.
    #

    def initialize(*arguments)
      super(File.join(ZIMBRAPATH,'bin','zmfreshclamctl'), ZIMBRAUSER, *arguments)
    end

  end

 

end

if $0 == __FILE__
  require 'test/unit'
  module Action
    #
    # Unit test case for ZMProv object
    class ZMAmavisdTest < Test::Unit::TestCase
      def testRun
        testObject = Action::ZMFreshclamctl.new('status')
        testObject.run
        puts testObject.response.include?("amavisd running pid")
      end

    end
  end
end


