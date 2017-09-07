#!/bin/env ruby -w
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2009 Yahoo
# Part of the command class structure.  This is the interface to zmloggerhostmap command
#
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end
require 'action/runcommand'
require 'tempfile'
require 'model/testbed'
module Action # :nodoc
  #
  # Perform zmloggerhostmap action.  This will invoke some zmloggerhostmap with some argument
  # from http server
  #
  class ZMLoggerhostmap < Action::RunCommandOnLogger

    #
    #  Create a ZMLoggerhostmap object.
    #
    def initialize(*arguments)
      super(File.join(ZIMBRAPATH,'bin','zmloggerhostmap'), ZIMBRAUSER, *arguments)
    end
  end

end

if $0 == __FILE__
  require 'test/unit'
  module Action
    #
    # Unit test case for ZMLoggerhostmap object
    class ZMLoggerhostmap < Test::Unit::TestCase
      def testHelp
          testObject = ZMLoggerhostmap.new('-h')
          puts YAML.dump(testObject.run)
      end
    end
  end
end