#!/bin/env ruby -w
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2008 Yahoo
# Part of the command class structure.  This is the interface to zmarchivesearch command
#
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end
require 'action/runcommand'
require 'tempfile'
require 'model/testbed'
module Action # :nodoc
  #
  # Perform zmmail action.  This will invoke some zmprov with some argument
  # from http server
  #
  class ZMArchivesearch < Action::RunCommandOnMailbox

    #
    #  Create a ZMArchivesearch object.
    #
    def initialize(*arguments)
      super(File.join(ZIMBRAPATH,'bin','zmarchivesearch'), ZIMBRAUSER, *arguments)
    end
  end


end

if $0 == __FILE__
  require 'test/unit'
  module Action
    #
    # Unit test case for ZMProv object
    class ZMArchivesearchTest < Test::Unit::TestCase
      def testHelp
          testObject = ZMArchivesearch.new('-h')
          puts YAML.dump(testObject.run)
      end
    end
  end
end