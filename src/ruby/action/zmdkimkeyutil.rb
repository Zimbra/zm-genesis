#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# Part of the command class structure.  This is the interface to zmdkimkeyutil commands
#
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end
require 'action/runcommand'
require 'action/stafsystem'
require 'action/zmprov'
require 'tempfile'
require 'model/testbed'
require 'model'

module Action # :nodoc
  #
  # Perform ZMDkimkeyutil action.
  #
  class ZMDkimkeyutil < Action::RunCommandOnMta
    #
    #  Create a ZMDkimkeyutil object.
    #
    def initialize(*arguments)
      super(File.join(ZIMBRAPATH,'libexec','zmdkimkeyutil'), ZIMBRAUSER, *arguments)
    end
  end

  class ZMOpendkimctl < Action::RunCommandOnMta
    #
    #  Create a zmopendkimctl object.
    #
    def initialize(*arguments)
      super(File.join(ZIMBRAPATH,'bin','zmopendkimctl'), ZIMBRAUSER, *arguments)
    end

  end
end

if $0 == __FILE__
  require 'test/unit'
  include Action
    
  # Unit test case for ZMDkimkeyutil object
  class ZMDkimkeyutilTest < Test::Unit::TestCase
    def testNoArgument
      testOne = Action::ZMDkimkeyutil.new('testme1')
      assert(testOne.to_str.include?("#{File.join(Command::ZIMBRAPATH, 'libexec', 'zmdkimkeyutil')} testme1"))
    end
  end

  # Unit test case for ZMOpendkimctl object
  class ZMOpendkimctlTest < Test::Unit::TestCase
    def testNoArgument
      testTwo = Action::ZMOpendkimctl.new('testme2')
      assert(testTwo.to_str.include?("#{File.join(Command::ZIMBRAPATH, 'bin', 'zmopendkimctl')} testme2"))
    end
  end
end

