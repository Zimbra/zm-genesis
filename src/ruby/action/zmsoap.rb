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
# Part of the command class structure.  This is the interface to zmsoap command
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
require 'rexml/document'
include REXML



module Action # :nodoc
  #
  # Perform ZMSoap action.  This will invoke some ZMSoap with some arguments

  #
  class ZMSoap < Action::Command

    #
    #  Create a ZMSoap object.
    #

    attr :label, true
    def initialize(*arguments)
      super()
      @runner = RunCommandOnMailbox.new(File.join(ZIMBRAPATH,'bin','zmsoap'), ZIMBRAUSER, *arguments)
      @tag = arguments.select{|w| w =~ /Request/}.compact.first[/(.*)Request/, 1] rescue 'UNDEFINED'
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

  class ZMSoapXml < ZMSoap
    def run
      mResult = @runner.run
      tagName = @tag + 'Response'
      [mResult[0], (Document.new mResult[1][/(<#{tagName}.*\/(#{tagName})?>)/m, 1] rescue nil)]
    end
  end

  class ZMSoapUtils

    def self.getAccountToken(account)
      return "ZMSoapUtils: #{account} is not a valid user" unless account.is_a?(Model::User)
      login = ZMSoap.new("-t account -m #{account.name} -p #{account.password} " +
                        "-v AuthRequest/account=#{account.name} ../password=#{account.password}").run
      return "ZMSoapUtils: Authentication failed for #{account}" unless login[0] == 0
      return login[1].match(/<authToken>(.*)<\/authToken>/)[1]
    end

    def self.getAdminAccountToken(account)
      return "ZMSoapUtils: #{account} is not a valid user" unless account.is_a?(Model::User)
      login = ZMSoap.new("-a #{account.name} -p #{account.password} " +
                        "-v AuthRequest/account=#{account.name} ../password=#{account.password}").run
      return "ZMSoapUtils: Authentication failed for #{account}" unless login[0] == 0
      return login[1].match(/<authToken>(.*)<\/authToken>/)[1]
    end

  end

end

if $0 == __FILE__
  require 'test/unit'
  module Action
    #
    # Unit test case for ZMSoap object
    class ZMSoapTest < Test::Unit::TestCase
      def testTOS
      end
    end
  end
end


