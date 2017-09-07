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
# Part of the command class structure, This is the interface to zmthrdump commands
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
  # Perform Zmamavisd action
  #
  class ZMThrdump < Action::RunCommandOnMailbox

    #
    #  Create a zmthrdump object
    #

    def initialize(*arguments)
      super(File.join(ZIMBRAPATH,'bin','zmthrdump'), ZIMBRAUSER, *arguments)
    end
  end
end

if $0 == __FILE__
  require 'test/unit'
  module Action
    #
    # Unit test case for ZMThrdump object
    class ZMThrdumpTest < Test::Unit::TestCase
      def testRun
        testObject = Action::ZMThrdump.new('-h')
        testObject.run
        puts testObject.response
        puts testObject.response.include?("help")
      end

    end
  end
end


