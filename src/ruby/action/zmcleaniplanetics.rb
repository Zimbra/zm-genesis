#!/usr/bin/ruby -w
#
# = action/zmcleaniplanetics.rb
#
# Copyright (c) 2009 Yahoo
#
# Written & maintained by Poonam Jaiswal
#
# Documented by Poonam Jaiswal
#
# Part of the command class structure.  This is the interface to zmcleaniplanetics
#
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end
require 'action/runcommand'
require 'tempfile'
require 'model/testbed'
module Action # :nodoc
  #
  # Perform zmcleaniplanetics action.
  # from http server
  #
  class ZMCleanIPlanetics < Action::RunCommand

    #
    #  Create a ZMCleanIPlanetics object.
    #
    def initialize(*arguments)
      super(File.join(ZIMBRAPATH,'bin','zmcleaniplanetics'), ZIMBRAUSER, *arguments)
    end
  end

end

if $0 == __FILE__
  require 'test/unit'
  module Action
    #
    # Unit test case for zmcleaniplanetics object
    class ZMCleanIPlanetics < Test::Unit::TestCase
      def testHelp
          testObject = ZMCleanIPlanetics.new('-h')
          puts YAML.dump(testObject.run)
      end
    end
  end
end