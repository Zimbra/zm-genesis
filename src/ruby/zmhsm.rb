#!/bin/env ruby
#
# = action/zmvolume.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# Part of the command class structure.  This is the interface to zmprov command
#
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end

require 'action/block'
require 'action/imap'
require 'action/runcommand'
require 'action/sendmail'
require 'action/stafsystem'
require 'action/verify'
require 'model/testbed'
require 'net/imap'
require 'set'
 
 
module Action # :nodoc
  module ZMHsmHelper
    def ZMHsmHelper.genDataValidation(targetHost, curUser, folder='INBOX')
      Action::Verify.new(Action::Block.new("Data Validation") do         
        a = Object.new
        b = Object.new
        class << a
          attr_reader :pass
          attr_writer :pass
          attr_reader :message
          attr_writer :message
        end
        class << b
          attr_reader :pass
          attr_writer :pass
          attr_reader :message
          attr_writer :message
        end   
        m = nil      
        begin
          m = Net::IMAP.new(targetHost, Model::IMAPSSL, true)       
          m.login(curUser.name, curUser.password)
          m.select(folder)    
          a.message = m.fetch(1..1, ['RFC822.TEXT'])[0].attr['RFC822.TEXT']
          a.pass = a.message.include?(curUser.name)
          b.message = m.search(["BODY", curUser.name])
          b.pass = b.message.to_set.superset?([1].to_set) 
        rescue    
          a.pass = false
          a.message = $!
          b.pass = false
          b.message = curUser
        ensure
          if(m)
            m.logout
            m.disconnect
          end
        end 
        [a, b]         
      end) do |mcaller, data| 
        mcaller.pass = data[0].pass && data[1].pass 
      end
    end
    
    def ZMHsmHelper.genVerifyMessages(targetHost, targetPath, errorMessage, &mblock)  
      gblock = block_given?
      Verify.new(RunCommandOnMailbox.new(File.join('/bin','ls'), 'root', '-R','-l',  
        targetPath)) do |mcaller, data|   
          msize = data[1].split.select { |mdata| mdata.include?('.msg')}.size 
          mcaller.pass = (data[0] == 0) && if(gblock)  
            mblock.call(msize)
          else             
            true
          end
          mcaller.message = errorMessage.strip + " size #{msize}" if not mcaller.pass
      end  
    end
    
    def ZMHsmHelper.genWait
      Block.new("Wait till finish") do
        stopRunning = false
        while(not stopRunning) do
          result = ZMHsm.new('-u').run[1]
          stopRunning = result.include?('Not currently running') || result.include?('No such file') 
          Kernel.sleep(1)
        end 
      end
    end
    
    def ZMHsmHelper.setServerPolicy(server = Model::TARGETHOST, policy='default')
      if policy == 'default'
        mResult = ZMProv.new('desc', '-a', 'zimbraHsmPolicy').run
        policy = mResult[1][/defaults\s+:\s+(.*)\s*$/, 1] if mResult[0] == 0
      end
      ZMProv.new('ms', server, 'zimbraHsmPolicy', "\"#{policy}\"")
    end
  end #end module
  #
  # Perform ZMVolume action.  This will invoke some zmprov with some argument
  # from http server
  #
  class ZMHsm < Action::RunCommandOnMailbox
  
    #
    #  Create a ZMHsm object.
    #
    attr_reader :response
    
    def initialize(*arguments)
      super(File.join(ZIMBRAPATH,'bin','zmhsm'), ZIMBRAUSER, *arguments)      
    end    
  end   
 
end

if $0 == __FILE__
  require 'test/unit'
  module Action
    #
    # Unit test case for ZMVolume object
    class ZMVolumeTest < Test::Unit::TestCase
      def testRun
        testObject = Action::ZMHsm.new
        testObject.run       
        puts testObject.response
      end  
      
      def testGenWait
        Action::ZMHsmHelper.genWait.run
      end
    end
  end
end


 