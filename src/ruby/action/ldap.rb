#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2008 Yahoo
#
#
# Part of the command class structure.  This is the interface to ldap* commands
#
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end
require 'action/runcommand'
require 'model/testbed'


module Action # :nodoc

  #
  # Perform ldap action.  This will invoke zmrestore with some arguments
  #
  class Ldap < Action::Command

    #
    #  Create a Ldap object.
    #
    def initialize(*arguments)
      super()
      self.timeOut = 2400 #timeout to 40 minutes

      @runner = RunCommandOnLdap.new(File.join(ZIMBRAPATH,'bin','ldap'), ZIMBRAUSER, *arguments)
    end

    def run
      @runner.run
    end

    def method_missing(name, *args)
      @runner.__send__(name, *args)
    end
  end

  class LdapSearch < Action::Command

    #
    #  Create a Ldap object.
    #
    def initialize(*arguments)
      super()
      self.timeOut = 2400 #timeout to 40 minutes

      @runner = RunCommandOnLdap.new(File.join(ZIMBRAPATH,'bin','ldapsearch'), ZIMBRAUSER, *arguments)
    end

    def run
      @runner.run
    end

    def method_missing(name, *args)
      @runner.__send__(name, *args)
    end
  end

  class LdapModify < Action::Command

    #
    #  Create a Ldap object.
    #
    def initialize(*arguments)
      super()
      self.timeOut = 2400 #timeout to 40 minutes
      @runner = RunCommandOnLdap.new(File.join(ZIMBRAPATH,'openldap','bin','ldapmodify'), ZIMBRAUSER, *arguments)
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
    # Unit test case for Ldap object
    class LdapTest < Test::Unit::TestCase
      def testRun
        testObject = Action::Ldap.new()
        testObject.run
        assert(testObject.exitstatus == 0, "usage")
      end
    end
  end
end


