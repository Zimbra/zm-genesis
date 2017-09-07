#!/usr/bin/ruby -w
#
# = action/getbuild.rb
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
require 'action/runcommand'
require 'action/stafsystem'
require 'tempfile'
require 'model/testbed'


module Action # :nodoc

  #
  # Perform zmprov action.  This will invoke some zmprov with some argument
  # from http server
  #
  class ZMProv < Action::RunCommand

    #
    #  Create a zmprov object.
    #

    def initialize(*arguments)
			super(File.join(ZIMBRAPATH,'bin','zmprov'), ZIMBRAUSER, *arguments)
    end
  end

  class CreateAccount < Action::ZMProv
    def initialize(*arguments)
      #check to see if zimbraMailHost is supplied
      unless(arguments.any? {|x| x == 'zimbraMailHost'})
          arguments = arguments + ['zimbraMailHost', Model::TARGETHOST.to_s]
      end
      super('ca', *arguments)
    end
  end

  class CreateAccounts < Action::Command
    def initialize(prefix = 'test', domain=Model::TARGETHOST, finish = 1000, password = Model::DEFAULTPASSWORD)
      super()
      @prefix = prefix
      @domain = domain
      #@targetHost = domain # change by patesh
      @targetHost = Model::TARGETHOST
      @finish = finish
      @password = password
      self.timeOut = 4800
    end

    def run
      #Create temp file
      tempFile = createTMP
      targetFileName = File.join('/tmp',File.basename(tempFile.path)+'e') # plus 'e' to avoid file collision
      if(Model::TARGETHOST == Model::CLIENTHOST)
        command = "/bin/cp #{tempFile.path} #{targetFileName}"
      else
        #Send it over to target host
        command = "#{Action::STAF} LOCAL FS COPY FILE #{tempFile.path} TOFILE #{targetFileName} TOMACHINE #{@targetHost} TEXT"
      end
      IO.popen(command).close_read
      RunCommand.new('/bin/env chown', 'root', ZIMBRAUSER,  targetFileName).run
      RunCommand.new('/bin/env chgrp', 'root', ZIMBRAUSER, targetFileName).run
      #Invoke zmprov there
      RunCommand.new(File.join(ZIMBRAPATH,'bin','zmprov'), ZIMBRAUSER, "< #{targetFileName}").run
      if(Model::TARGETHOST == Model::CLIENTHOST)
        command = "/bin/rm -f #{tempFile.path} #{targetFileName}"
      else
        command = "#{Action::STAF} #{@targetHost} FS DELETE ENTRY #{targetFileName} CONFIRM"
      end
      IO.popen(command).close_read
    end

    def createTMP(pattern = ["ca #{@prefix}","@#{@domain} #{@password} zimbraMailHost #{@domain}\n"])
      tempFile = Tempfile.new('accounts')
      tempFile.open
      1.upto(@finish) do |i|
        tempFile.print(pattern[0],i,pattern[1])
      end
      tempFile.close(false)
      tempFile
    end

    def to_str
      "Action: CreateAccounts #{@prefix} 0 #{@finish} #{@domain}"
    end
  end

  class DeleteAccount < Action::ZMProv
    def initialize(*arguments)
      super('da', *arguments)
    end
  end

  class DeleteAccounts < Action::CreateAccounts
    def createTMP(pattern = ["da #{@prefix}","@#{@domain}\n"])
      super(pattern)
    end

    def to_str
      "Action: DeleteAccounts #{@prefix} 0 #{@finish} #{@domain}"
    end
  end

  class ModifyAccount < Action::ZMProv
    def initialize(*arguments)
      super('ma', *arguments)
    end
  end

  class SetIMAPFlag < Action::ModifyAccount
    def initialize(accountName = nil, flag = true)
      super(accountName, 'zimbraImapEnabled', flag)
    end
  end
  
  class AddListMembers < Action::CreateAccounts
    def initialize(dl, *arguments)
      @list = dl
      super(*arguments)
    end
    def createTMP(pattern = ["adlm #{@list} #{@prefix}","@#{@domain}\n"])
      super(pattern)
    end

    def to_str
      "Action: AddListMembers #{@list} #{@prefix} 0 #{@finish} #{@domain}"
    end
  end
end

if $0 == __FILE__
  require 'test/unit'
  module Action
    #
    # Unit test case for ZMProv object
    class ZMProvTest < Test::Unit::TestCase
      def testRun
        testObject = Action::ZMProv.new('ca '+ Model::TARGETHOST.cUser('remote2')+ ' zimbra')
        testObject.run
        assert(testObject.response.include?('Returen Code: 1') == false)
      end

      def testTOS
        testObject = Action::ZMProv.new('ca yes')
        puts testObject
      end

       def testTemp
        testObject = Action::CreateAccounts.new
        testObject.createTMP
       end

      def testCreatAccounts
        testObject = Action::CreateAccounts.new
        require 'benchmark'
        Benchmark.bm(20) do |x|
          x.report("create10000:") {testObject.run }
        end
      end

      def testDeleteAccounts
        testObject = Action::DeleteAccounts.new
        require 'benchmark'
        Benchmark.bm(20) do |x|
          x.report("delete10000:") {testObject.run }
        end
      end

       def testTimeOut
          testObject = Action::CreateAccounts.new
          assert(testObject.timeOut == 4800)
       end
    end
  end
end


