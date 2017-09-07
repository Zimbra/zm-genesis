#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2012 VMWare
#
#
# Part of the command class structure.  This is the interface to zmslapcat command
#
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end
require 'action/runcommand'
require 'model/testbed'


module Action # :nodoc

  #
  # Perform zmslapcat action.
  #
  class ZMSlapcat < Action::Command

    #
    #  Create a zmslapcat object.
    #
    def initialize(*arguments)
      super()
      self.timeOut = 2400 #timeout to 40 minutes

      @runner = RunCommandOnLdap.new(File.join(ZIMBRAPATH,'libexec','zmslapcat'), ZIMBRAUSER, *arguments)
    end

    def run
      @runner.run
    end

    def method_missing(name, *args)
      @runner.__send__(name, *args)
    end
  end
  
  #
  # Perform zmslapcat action.
  #
  class ZMSlapadd < Action::Command

    #
    #  Create a zmslapadd object.
    #
    def initialize(*arguments)
      super()
      self.timeOut = 2400 #timeout to 40 minutes

      @runner = RunCommandOnLdap.new(File.join(ZIMBRAPATH,'libexec','zmslapadd'), ZIMBRAUSER, *arguments)
    end

    def run
      @runner.run
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
    # Unit test case for zmslapcat object
    class ZMSlapcatTest < Test::Unit::TestCase
      def testRun
        testObject = Action::ZMSlapcat.new()
        testObject.run
        assert(testObject.exitstatus != 0, "usage")
      end
    end
    
    # Unit test case for zmslapadd object
    class ZMSlapcatTest < Test::Unit::TestCase
      def testRun
        testObject = Action::ZMSlapadd.new()
        testObject.run
        assert(testObject.exitstatus != 0, "usage")
      end
    end
  end
end


