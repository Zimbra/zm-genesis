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
# Part of the command class structure.  This is the interface to zmbackup command
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
  module ZMBackupHelper

    def ZMBackupHelper.genDataValidation(targetHost, curUser, mailbox, checkArray)
      Action::Verify.new(Action::Block.new("Data Validation") do
        a = Object.new
        b = Object.new
        class << a
          attr :pass, true
          attr :message, true
        end
        class << b
          attr :pass, true
          attr :message, true
        end
        m = nil
        begin
          m = Net::IMAP.new(targetHost, Model::IMAPSSL, true)
          m.login(curUser.name, curUser.password)
          m.select(mailbox)
          a.pass = true;
          b.pass = true;
          b.message = []
          a.message = m.fetch(1..checkArray.size,['RFC822.TEXT'])
          checkArray.each_with_index do |item, index|
            a.pass = a.pass && a.message[index].attr['RFC822.TEXT'].include?(item)
            currResult = m.search(["BODY", item])
            b.message = b.message << currResult
            b.pass = b.pass && currResult.to_set.superset?([index+1].to_set)
          end
        rescue
          a.pass = false
          a.message = $!
          b.pass = false
          b.message =  $!.backtrace.join("\n")
        ensure
          if(m)
            m.logout
            m.disconnect
          end
        end
        [a, b]
      end) do |mcaller, data|
        mcaller.pass = data[0].pass && data[1].pass
      end #end verify
    end #end def

    def ZMBackupHelper.genIMAPCreateFolder(curUser, folder, targetHost)
      Action::Block.new("Creating #{folder} through IMAP") do
        m = nil
        begin
          m = Net::IMAP.new(targetHost, Model::IMAPSSL, true)
          m.login(curUser.name, curUser.password)
          m.create(folder)
        rescue
        ensure
          if(m)
            m.logout
            m.disconnect
          end
        end
      end
    end

    def ZMBackupHelper.genLDAPValidate(backup, nMount ='backup', zip=false)
      Action::Verify.new(backup) do |mcaller, data|
        kind = zip ? 'gzip' : 'text'
        fileName = File.join(Command::ZIMBRAPATH, nMount, 'sessions',  backup.label, 'ldap', 'ldap.bak*')
        mcaller.pass = RunCommandOnMailbox.new('file', Command::ZIMBRAUSER, fileName).run[1].include?(kind) &&
            !RunCommandOnMailbox.new('zgrep', Command::ZIMBRAUSER, '"uid: zimbra"', fileName).run[1].split(/\n/).select {|w| w =~ /\buid: zimbra\b/}.empty?
        if(not mcaller.pass)
          class << mcaller
            attr :errorDetail, true
              attr :errorDetail2, true
          end
          mcaller.errorDetail = YAML.dump(RunCommandOnMailbox.new('file', Command::ZIMBRAUSER, fileName).run[1].include?(kind))
          mcaller.errorDetail2 = YAML.dump(!RunCommandOnMailbox.new('zgrep', Command::ZIMBRAUSER, '"uid: zimbra"', fileName).run[1].split(/\n/).select {|w| w =~ /\buid: zimbra\b/}.empty?)
        end
      end
    end

    ### code added by Paresh for Bug Verification 26624
    def ZMBackupHelper.verifyZipBackup(accounts,backup,nMount)
      Action::Verify.new(accounts) do |mcaller, data|
        response_accounts  = accounts.run[1]
        label_backup = backup.run[2]
        response_lines = response_accounts.split("\n")
        all_accounts = []

        if (response_lines.include?('Data       :'))
          9.upto(response_lines.length - 8) do  |i|
            if response_lines[i].include?('zip')
              all_accounts.push(response_lines[i])
            end
            i = i+1
          end
        else
          response_lines.each do |x|
            all_accounts.push(x) if x.include?('zip')
          end
        end
        all_accounts.each do |z|
          zimbraids = RunCommand.new(File.join(Command::ZIMBRAPATH,'bin','zmprov'), Command::ZIMBRAUSER, 'ga', z, 'zimbraId' ).run[1]
          zimbraid = zimbraids.match('\w+-\w+-\w+-\w+-\w+')[0]
          dir1 = zimbraid.slice(0..2)
          dir2 = zimbraid.slice(3..5)
          filename = []
          # curruntly checking for default number of zip files i.e. 4. Need to check dynamically using local conf value.
          1.upto(4) do |i|
            zipfilename = 'blobs-'+ i.to_s + '.zip'
            filename.push(File.join(nMount,'sessions',label_backup,'accounts',dir1,dir2,zimbraid,'blobs',zipfilename))
          end
          filename.each do |file|

            mcaller.pass = (RunCommandOnMailbox.new('ls', 'root', file ).run[0] == 0)
            if( not mcaller.pass)
              class << mcaller
                attr :errorDetail, true
                mcaller.errorDetail = []
              end
              mcaller.errorDetail << YAML.dump(RunCommandOnMailbox.new('ls', 'root', file ).run)

            end # if
          end # do
        end # do
      end # verify
    end # def
    ### End code by Paresh for Bug Verification 26624

  end #end module

  #
  # Perform zmbackup action.  This will invoke some zmbackup with some argument
  # from http server
  #
  class ZMBackup < Action::Command

    #
    #  Create a ZMBackup object.
    #

    attr :label, true
    attr :timestamp, true
    def initialize(*arguments)
      super()
      @runner = RunCommandOnMailbox.new(File.join(ZIMBRAPATH,'bin','zmbackup'), ZIMBRAUSER, '-sync', *arguments)
      @label = ''
      @date = RunCommandOnMailbox.new('/bin/date', 'root', '+%Y/%m/%d-%H:%M:%S')
      @timestamp = ''
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

  class Fullbackup < Action::ZMBackup
    def initialize(*arguments)
      if(arguments.size == 0)
        super('--fullBackup', '-d', '-a', 'all')
      else
        super('--fullBackup', '-d', *arguments)
      end
    end

    def run
      super
      if(self.exitstatus == 0 && self.response != nil)
        begin
          @label = self.response.match('(full-\d+\.\d+\.\d+)')[0]
          @date.run
          @timestamp = @date.response.match(/\d{4}\/\d{2}\/\d{2}-\d{2}:\d{2}:\d{2}/)
        rescue
          @label = ''
          self.exitstatus = 1
        end
      end
      [self.exitstatus, self.response, @label]
    end

    def clabel
      return self.method("label")
    end

    def ctimestamp
      return self.method("timestamp")
    end
  end

  class Incbackup < Action::ZMBackup
    def initialize(*arguments)
      if(arguments.size == 0)
        super('--incrementalBackup', '-d', '-a', 'all')
      else
        super('--incrementalBackup', '-d', *arguments)
      end
    end

    def run
      super
      if(self.exitstatus == 0 && self.response != nil)
        @label = self.response.match(/((incr|full)-\d+\.\d+\.\d+)/)[0] rescue self.response
        @date.run
        @timestamp = @date.response.match(/\d{4}\/\d{2}\/\d{2}-\d{2}:\d{2}:\d{2}/)
      end
      [self.exitstatus, self.response, @label]
    end

    def clabel
      return self.method("label")
    end

    def ctimestamp
      return self.method("timestamp")
    end

  end
end

if $0 == __FILE__
  require 'test/unit'
  module Action
    #
    # Unit test case for ZMBackup object
    class ZMBackupTest < Test::Unit::TestCase

      def testRun
        testObject = Action::ZMBackup.new
        testObject.run
        assert(testObject.exitstatus == 1)
      end

      def testFull
        testObject = Action::Fullbackup.new
        testObject.run
        assert(testObject.label.include?('full'))
      end

      def testIncbackup
        testObject = Action::Incbackup.new
        testObject.run
        assert(testObject.exitstatus == 0)
      end

      def testTOS
        testObject = Action::ZMBackup.new('ca yes')
        assert(testObject.to_str.include?("ca yes"))
      end

      def testGenValidation
        puts YAML.dump(ZMBackupHelper.genDataValidation(Model::TARGETHOST, 'one', 'two', 'three'))
      end

      def testGenIMAP
        puts YAML.dump(ZMBackupHelper.genIMAPCreateFolder('targetHost', 'curUser', 'folder'))
      end
#
       def testTimeOut
         testObject = Action::ZMBackup.new
         assert(testObject.timeOut == 2400)
       end
    end
  end
end


