#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2010 Vmware
#
#
# Part of the command class structure.  This is the interface to zmjsprecompile command
#
if($0 == __FILE__)
   mydata = File.expand_path(__FILE__).reverse.sub(/.*?ybur/,"").reverse; $:.unshift(File.join(mydata, 'ruby')) 
end
require "action/command"
require "action/block"
require "action/verify"
require "action/runcommand"
require "model"



module Action # :nodoc
  #
  # Perform ZMBlobchk action.  This will invoke some ZMBlobchk with some arguments

  #
  class ZMJsprecompile < Action::Command

    #
    #  Create a ZMJsprecompile object.
    #

    attr :label, true
    def initialize(*arguments)
      super()
      @runner = RunCommand.new(File.join(ZIMBRAPATH,'libexec','zmjsprecompile'), ZIMBRAUSER, *arguments)
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
    # Unit test case for ZMJsprecompile object
    class ZMJsprecompileTest < Test::Unit::TestCase

      def testTOS
        testObject = Action::ZMJsprecompile.new('ca yes')
        puts YAML.dump(testObject)
        assert(testObject.to_str.include?("ca yes"))
      end

    end
  end
end


