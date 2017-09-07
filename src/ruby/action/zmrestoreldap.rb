#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2006 Zimbra
#
#
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end 
require 'action/block'
require 'action/runcommand'
require 'action/system' 
require 'action/verify'
require 'set'
require 'model/testbed'
require 'net/imap'

module Action # :nodoc
class ZMRestoreLDAP < Action::Command
  
    #
    #  Create a ZMBackup object.
    # 
    def initialize(*arguments)
      super()
      @runner = RunCommandOnLdap.new(File.join(ZIMBRAPATH,'bin','zmrestoreldap'), ZIMBRAUSER, *arguments)        
    end
    
    def run
      @runner.run
      [exitstatus, response, @label]
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
    # Unit test case for ZMBackup object
    class ZMRestoreLDAPTest < Test::Unit::TestCase
      
      def testRun         
        testObject = Action::ZMRestoreLDAP.new
        testObject.run
        puts YAML.dump(testObject)
      end 
    end
  end
end


 