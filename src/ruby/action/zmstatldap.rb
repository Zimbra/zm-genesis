#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$

if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end

require "action/command"
require "action/runcommand"
require "model"

module Action # :nodoc
  #
  # Perform ZMStatldap action.

  #
  class ZMStatldap < Action::Command

    #
    #  Create a ZMStatldap object.
    #

    attr :label, true
    def initialize(*arguments)
      super()
      @runner = RunCommand.new(File.join(ZIMBRAPATH,'libexec','zmstat-ldap'), ZIMBRAUSER, *arguments)
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
    # Unit test case for ZMStatldap object
    class ZMStatldap < Test::Unit::TestCase
    end
  end
end


