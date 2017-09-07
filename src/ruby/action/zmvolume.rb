#!/usr/bin/ruby -w
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
require 'action/runcommand'
require 'action/sendmail'
require 'action/stafsystem'
require 'action/verify'
require 'action/waitqueue'
require 'model/testbed'


module Action # :nodoc
  module ZMVolumeHelper

    def ZMVolumeHelper.genCreateSet(mfilePath, volumeName, volumeType, pathArgument = nil, maction = nil)
         # Relative path
      [
        RunCommandOnMailbox.new(File.join('/bin','mkdir'), 'root', mfilePath),
        RunCommandOnMailbox.new(File.join('/bin','chgrp'), 'root', Command::ZIMBRAUSER, mfilePath),
        RunCommandOnMailbox.new(File.join('/bin','chown'), 'root', Command::ZIMBRAUSER, mfilePath),
        #Create new and set
        Verify.new(maction || ZMVolume.new('-a','-n', volumeName , '-t', volumeType, '-p',
          pathArgument || mfilePath)) do |mcaller, data|
          data[1] =~ /Volume (\d+)/
          cVolume = $1
          cResult = ZMVolume.new('-sc','-id', cVolume,'-t', volumeType).run
          mcaller.pass = (data[0] == 0) && (cResult[0] == 0)
          if(not mcaller.pass)
            class << mcaller
              attr :secondaction, true
            end
            mcaller.secondaction = cResult
          end
        end
      ]
    end

    def ZMVolumeHelper.listToHash(data)
      data.split(/ Volume/).inject({}) do |sum, i|
        if( i =~ /id: (\d+).* name: (\w+).* type: (\w+)/m )
          sum[$2] = { :id => $1, :type => $3}
        end
        sum
      end
    end


    def ZMVolumeHelper.genDeleteByName(mname)
      Verify.new(ZMVolume.new('-l')) do |mcaller, data|
        lHash = ZMVolumeHelper.listToHash(data[1])

        class << mcaller
          attr :response, true
        end

        if(lHash.has_key?(mname))
          mcaller.response = mresponse = ZMVolume.new('-d','-id', lHash[mname][:id]).run
          mcaller.pass = (mresponse[0] == 0)
        else
          mcaller.pass = false
          mcaller.response = [1, "Name #{mname} not found", "Not found"]
        end
      end
    end

    def ZMVolumeHelper.genGetIdByName(mname)
      Verify.new(ZMVolume.new('-l')) do |mcaller, data|
        lHash = ZMVolumeHelper.listToHash(data[1])

        class << mcaller
          attr :response, true
          attr :id, true
        end

        if(lHash.has_key?(mname))
          mcaller.response = [0, lHash[mname][:id]]
          mcaller.pass = true
          mcaller.id = mcaller.response[1]
        else
          mcaller.pass = false
          mcaller.response = [1, "Name #{mname} not found", "Not found"]
        end
      end
    end

    def ZMVolumeHelper.genEditVerify(description, mid, listOption, checkString)
      Verify.new(Block.new(description) do
        ZMVolume.new('-e', '-id', mid.id, *listOption).run
      end) do |mcaller, data|
        response = ZMVolume.new('-l', '-id', mid.id).run
        mcaller.pass = response[0] == 0 &&
        response[1].include?(checkString)
      end
    end

    def ZMVolumeHelper.genSendVerify(address, mfilePath, message)
      msize = 0
      [
        Action::WaitQueue.new,
        Verify.new(RunCommandOnMailbox.new(File.join('/bin','ls'), 'root', '-R','-l',  mfilePath)) do |mcaller, data|
            msize = data[1].split.select { |mdata| mdata.include?('.msg')}.size
            mcaller.pass = (data[0] == 0)
        end,
        # Send an email
        SendMail.new(address, message, Model::TARGETHOST),
        # Wait till queue is empty
        Action::WaitQueue.new,


        # Verify the message is placed correctly
        Verify.new(RunCommandOnMailbox.new(File.join('/bin','ls'), 'root', '-R','-l', mfilePath )) do |mcaller, data|
            nsize = data[1].split.select { |mdata| mdata.include?('.msg')}.size
            mcaller.pass = (data[0] == 0) && (nsize == msize + 1)
            if(not mcaller.pass)
              class << mcaller
                attr :errormessage, true
              end
              mcaller.errormessage = "Message fails to reach appropriate volume #{msize} #{nsize} #{mfilePath}"
            end
        end,
      ]
    end

    def ZMVolumeHelper.genReset
      [
        # Revert to previous setting
        Verify.new(ZMVolume.new('-sc','-id','1')) do |mcaller, data|
          mcaller.pass = (data[0] == 0) && data[1].include?('Volume 1 is now the current primaryMessage')
        end,

        Verify.new(ZMVolume.new('-sc','-id','2')) do |mcaller, data|
          mcaller.pass = (data[0] == 0) && data[1].include?('Volume 2 is now the current index volume')
        end,
      ]
    end

    def ZMVolumeHelper.Error(checkString)
      proc do |mcaller, data|
        mcaller.pass =
          (data[0] == 1) &&
          (data[1].include?(checkString))
        mcaller.message = "Fail check #{checkString}" unless mcaller.pass
      end
    end
  end

 def ZMVolumeHelper.genDataValidation(targetHost, curUser,n)
      Action::Verify.new(Action::Block.new("Data Validation") do
        a = Object.new
        class << a
          attr :pass, true
          attr :message, true
        end
        m = nil
        begin
          m = Net::IMAP.new(targetHost, Model::IMAPSSL, true)
          m.login(curUser.name, curUser.password)
          m.select("INBOX")
          a.message = m.fetch(1..n, ['RFC822.TEXT'])  # [0].attr['RFC822.TEXT']
          a.pass = true #m.message.include?(curUser.name)
        rescue
          a.pass = false
          a.message = $!
        ensure
          if(m)
            m.logout
            m.disconnect
          end
        end
        [a]
      end) do |mcaller, data|
        mcaller.pass = data[0].pass
      end
    end


  #
  # Perform ZMVolume action.  This will invoke some zmprov with some argument
  # from http server
  #
  class ZMVolume < Action::RunCommandOnMailbox

    #
    #  Create a zmprov object.
    #
    attr_reader :response

    def initialize(*arguments)
      super(File.join(ZIMBRAPATH,'bin','zmvolume'), ZIMBRAUSER, *arguments)
        
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
        testObject = Action::ZMVolume.new('-l')
        testObject.run
        puts testObject.response
      end

      def testCreateSet
        puts YAML.dump(Action::ZMVolumeHelper.genCreateSet('1','2','3'))
        puts YAML.dump(Action::ZMVolumeHelper.genCreateSet('1','2','3','4'))
      end

      def testSendEmail
        puts YAML.dump(Action::ZMVolumeHelper.genSendVerify('hello','1','2'))
      end

      def testRestore
        puts YAML.dump(Action::ZMVolumeHelper.genReset)
      end

      def testDeleteByName
        puts YAML.dump(Action::ZMVolumeHelper.genDeleteByName('testvolume8'))
      end
    end
  end
end


