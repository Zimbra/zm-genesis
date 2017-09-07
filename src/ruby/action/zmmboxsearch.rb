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
# Part of the command class structure.  This is the interface to zmmboxsearch command
#
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end
require "action/command"
require "action/clean"
require "action/block"
require "action/verify"
require "action/runcommand"
require "action/waitqueue"
require "action/zmprov"
require "model"
require 'net/smtp'



module Action # :nodoc
#  module ZMMboxsearchHelper
#
#    def ZMMboxsearchHelper.genDataValidation(targetHost, curUser, mailbox, checkArray)
#      Action::Verify.new(Action::Block.new("Data Validation") do
#        a = Object.new
#        b = Object.new
#        class << a
#          attr :pass, true
#          attr :message, true
#        end
#        class << b
#          attr :pass, true
#          attr :message, true
#        end
#        m = nil
#        begin
#          m = Net::IMAP.new(targetHost, Model::IMAPSSL, true)
#          m.login(curUser.name, curUser.password)
#          m.select(mailbox)
#          a.pass = true;
#          b.pass = true;
#          b.message = []
#          a.message = m.fetch(1..checkArray.size,['RFC822.TEXT'])
#          checkArray.each_with_index do |item, index|
#            a.pass = a.pass && a.message[index].attr['RFC822.TEXT'].include?(item)
#            currResult = m.search(["BODY", item])
#            b.message = b.message << currResult
#            b.pass = b.pass && currResult.to_set.superset?([index+1].to_set)
#          end
#        rescue
#          a.pass = false
#          a.message = $!
#          b.pass = false
#          b.message =  $!.backtrace.join("\n")
#        ensure
#          if(m)
#            m.logout
#            m.disconnect
#          end
#        end
#        [a, b]
#      end) do |mcaller, data|
#        mcaller.pass = data[0].pass && data[1].pass
#      end #end verify
#    end #end def
#
#    def ZMMboxsearchHelper.genLDAPValidate(backup)
#      Action::Verify.new(backup) do |mcaller, data|
#       fileName = File.join(Command::ZIMBRAPATH, 'backup', 'sessions',  backup.label, 'ldap', 'ldap.bak')
#        mcaller.pass = (RunCommand.new('file', Command::ZIMBRAUSER, fileName).run[1].include?('text')) &&
#            (RunCommand.new('grep', Command::ZIMBRAUSER, 'postmaster', fileName).run[1].include?('uid'))
#        if(not mcaller.pass)
#          class << mcaller
#            attr :errorDetail, true
#              attr :errorDetail2, true
#          end
#          mcaller.errorDetail = YAML.dump(RunCommand.new('file', Command::ZIMBRAUSER,
#            fileName = File.join(Command::ZIMBRAPATH, 'backup', 'sessions',  backup.label, 'ldap', 'ldap.bak')).run[1].include?('text'))
#          mcaller.errorDetail2 =   YAML.dump(RunCommand.new('grep', Command::ZIMBRAUSER, 'postmaster', fileName).run[1].include?('uid'))
#
#        end
#      end
#    end
#  end #end module

  #
  # Perform ZMMboxsearch action.  This will invoke some ZMMboxsearch with some arguments

  #
  class ZMMboxsearch < Action::Command

    #
    #  Create a ZMMboxsearch object.
    #

    attr :label, true
    def initialize(*arguments)
      super()
      @runner = RunCommandOnMailbox.new(File.join(ZIMBRAPATH,'bin','zmmboxsearch'), ZIMBRAUSER, *arguments)
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
    # Unit test case for ZMMboxsearch object
    class ZMMboxsearchTest < Test::Unit::TestCase

      def testTOS
#        testObject = Action::ZMMboxsearch.new('ca yes')
#       assert(testObject.to_str.include?("ca yes"))
      end
#
    end
  end
end


