#!/usr/bin/ruby -w
#
# = action/zmldappasswd.rb
#
# Copyright (c) 2008 Yahoo
#
# Written & maintained by Paresh Naik
#
# Documented by Paresh Naik
#
# Part of the command class structure.  This is the interface to zmldappasswd
#
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end
require 'action/runcommand'
require 'tempfile'
require 'model/testbed'
module Action # :nodoc
  #
  # Perform zmldappasswd action.
  # from http server
  #
  class ZMLdapPasswd < Action::RunCommandOnLdap

    #
    #  Create a ZMLdapPasswd object.
    #
    def initialize(*arguments)
      super(File.join(ZIMBRAPATH,'bin','zmldappasswd'), ZIMBRAUSER, *arguments)
    end
  end

end

if $0 == __FILE__
  require 'test/unit'
  module Action
    #
    # Unit test case for ZMProv object
    class ZMLdapPasswdTest < Test::Unit::TestCase
      def testHelp
          testObject = ZMLdapPasswd.new('-h')
          puts YAML.dump(testObject.run)
      end
    end
  end
end