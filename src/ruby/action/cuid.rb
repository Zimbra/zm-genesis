#!/usr/bin/ruby -w
#
# = action/untar.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# Part of the command class structure.  This impelments switching user id
# 
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end
 
require 'action/command'
 
module Action # :nodoc
  #
  #  Perform change of user id
  #
  class CUid < Action::Command
    #
    # Objection creation
    # bind cuid object with specified +username+.  It is defaulted to ZIMBRAUSER
    def initialize(userName = ZIMBRAUSER)
      super()
      @userName = userName
      @oldEUID = nil
      @oldEGID = nil
    end
     
    #
    # Execute change user id action
    #  
    def run()
      super()  
      userID, groupID = `id #{@userName}`.scan(/\d+/) #fetch user gid and uid
      userID = userID.to_i
      groupID = groupID.to_i
      @oldEGID = Process::Sys.getegid
      @oldEUID = Process::Sys.geteuid
      switchUser(userID, groupID)
    rescue NotImplementedError
      @oldEGID = nil
      @oldEUID = nil
    end
    
    def revert()
      if(@oldEGID != nil && @oldEUID != nil)
        switchUser(@oldEUID, @oldEGId)
      end
    end
    
    def switchUser(uid, gid)
      Process::Sys.setegid(gid)
      Process::Sys.seteuid(uid)
    end
    
    def to_str 
      "Action:CUid name:#{@userName}"
    end  
  end
    
  
end

if $0 == __FILE__
  require 'test/unit'  
  
  module Action
    # Unit test cases for CUid
    class CUidTest < Test::Unit::TestCase     
      def testRun
        Dir::mkdir('touchtest')
        testObject = Action::CUid.new('bhwang')
        testObject.run
        Dir::delete('touchtest')
      end
      
      def testTOS
        testObject = Action::CUid.new
        puts testObject
      end
    end
  end
end
 
  

