#!/bin/env ruby -w
#
# $File$
# $DateTime$
#
# $Revision$
# $Modified by: gzhang $
# $Author$
#
# Part of the command class structure.  This is the interface to zm*ctl commands
#
if($0 == __FILE__)
  mydata = $:.unshift(File.split(Dir.getwd)[0])   #append library path
end

require 'action/runcommand'
require 'action/stafsystem'
require 'tempfile'
require 'model/testbed'


module Action # :nodoc

  #
  # Perform Zmamavisd action.
  #
  class ZMAmavisd < Action::RunCommandOnMta

    #
    #  Create a Zmamavisd object.
    #

    def initialize(*arguments)
      super(File.join(ZIMBRAPATH,'bin','zmamavisdctl'), ZIMBRAUSER, *arguments)
    end

  end

  class ZMAntispam < Action::RunCommandOnAntispam

    #
    #  Create a ZMAntispam object.
    #

    def initialize(*arguments)
      super(File.join(ZIMBRAPATH,'bin','zmantispamctl'), ZIMBRAUSER, *arguments)
    end

  end

  class ZMAntivirusctl < Action::RunCommandOnAntivirus

    #
    #  Create a ZMAntivirusctl object.
    #

    def initialize(*arguments)
      super(File.join(ZIMBRAPATH,'bin','zmantivirusctl'), ZIMBRAUSER, *arguments)
    end

  end

  class ZMApachectl < Action::RunCommandOnSpell

    #
    #  Create a ZMAntivirusctl object.
    #

    def initialize(*arguments)
      super(File.join(ZIMBRAPATH,'bin','zmapachectl'), ZIMBRAUSER, *arguments)
    end

  end

  class ZMArchivectl < Action::RunCommandOnMta

    #
    #  Create a ZMArchivectl object.
    #

    def initialize(*arguments)
      super(File.join(ZIMBRAPATH,'bin','zmarchivectl'), ZIMBRAUSER, *arguments)
    end

  end

  class ZMClamdctl < Action::RunCommandOnMta

    #
    #  Create a ZMClamdctl object.
    #

    def initialize(*arguments)
      super(File.join(ZIMBRAPATH,'bin','zmclamdctl'), ZIMBRAUSER, *arguments)
    end

  end

  class ZMConvertctl < Action::RunCommandOnConvertd

    #
    #  Create a zmconvertctl object.
    #

    def initialize(*arguments)
      super(File.join(ZIMBRAPATH,'bin','zmconvertctl'), ZIMBRAUSER, *arguments)
    end

  end

  class ZMLoggerctl < Action::RunCommandOnLogger

    #
    #  Create a ZMLoggerctl object.
    #

    def initialize(*arguments)
      super(File.join(ZIMBRAPATH,'bin','zmloggerctl'), ZIMBRAUSER, *arguments)
    end

  end

  class ZMLogswatchctl < Action::RunCommandOnLogger

    #
    #  Create a ZMLogswatchctl object.
    #

    def initialize(*arguments)
      super(File.join(ZIMBRAPATH,'bin','zmlogswatchctl'), ZIMBRAUSER, *arguments)
    end

  end

  class ZMMailboxdctl < Action::RunCommandOnMailbox

      #
      #  Create a ZMMogswatchctl object.
      #

      def initialize(*arguments)
        super(File.join(ZIMBRAPATH,'bin','zmmailboxdctl'), ZIMBRAUSER, *arguments)
      end

      def self.waitForJetty(host = nil)
        v(cb("Wait until jetty is up and running") do
          response = [1, '']
          until response[1] =~ /(INFO.*\[main\] log - jetty-6\.\d+\.|Zimbra server process is running)/ do
            response = Action::RunCommandOnMailbox.new('tail','root', '-100',
                                              '/opt/zimbra/log/zmmailboxd.out', host).run
            sleep 1
          end
          response
        end) do |mcaller, data|
          mcaller.pass = data[0] == 0 && data[1] =~ /(INFO.*\[main\] log - jetty-6\.\d+\.|Zimbra server process is running)/
          sleep 5
        end
      end
      
      def self.waitForMailboxd(host = nil)
        v(cb("Wait until mailboxd is up and running") do
          response = [1, '']
          until response[1] =~ /INFO  \[main\] \[\] (log - Started SelectChannelConnector@0\.0\.0\.0:7072|AutoDiscoverServlet - Starting up)/ do
            response = Action::RunCommandOnMailbox.new('tail','root', '-10',
                                              '/opt/zimbra/log/mailbox.log', host).run
            sleep 1
          end
          response
        end) do |mcaller, data|
          mcaller.pass = data[0] == 0 && data[1] =~ /INFO  \[main\] \[\] (log - Started SelectChannelConnector@0\.0\.0\.0:7072|AutoDiscoverServlet - Starting up)/
        end
      end

  end

  class ZMMtaconfigctl < Action::RunCommand

      #
      #  Create a ZMMtaconfigctl object.
      #

      def initialize(*arguments)
        super(File.join(ZIMBRAPATH,'bin','zmconfigdctl'), ZIMBRAUSER, *arguments)
      end

  end

  class ZMConfigdctl < Action::RunCommand

      #
      #  Create a ZMConfigdctl object.
      #

      def initialize(*arguments)
        super(File.join(ZIMBRAPATH,'bin','zmconfigdctl'), ZIMBRAUSER, *arguments)
      end

  end

  class ZMMtactl < Action::RunCommandOnMta

      #
      #  Create a ZMMtactl object.
      #

      def initialize(*arguments)
        super(File.join(ZIMBRAPATH,'bin','zmmtactl'), ZIMBRAUSER, *arguments)
      end

  end

  # depricated
  #class ZMPerditionctl < Action::RunCommand
  #
  #    #
  #    #  Create a ZMPerditionctl object.
  #    #
  #
  #    def initialize(*arguments)
  #      super(File.join(ZIMBRAPATH,'bin','zmperditionctl'), ZIMBRAUSER, *arguments)
  #    end
  #
  #end

  class ZMSaslauthdctl < Action::RunCommandOnMta

      #
      #  Create a ZMSaslauthdctl object.
      #

      def initialize(*arguments)
        super(File.join(ZIMBRAPATH,'bin','zmsaslauthdctl'), ZIMBRAUSER, *arguments)
      end

  end

  class ZMSpellctl < Action::RunCommandOnMailbox

      #
      #  Create a zmspellctl object.
      #

      def initialize(*arguments)
        super(File.join(ZIMBRAPATH,'bin','zmspellctl'), ZIMBRAUSER, *arguments)
      end

  end

  class ZMStatctl < Action::RunCommand

      #
      #  Create a zmstatctl object.
      #

      def initialize(*arguments)
        super(File.join(ZIMBRAPATH,'bin','zmstatctl'), ZIMBRAUSER, *arguments)
      end

  end

  class ZMStorectl < Action::RunCommandOnMailbox

      #
      #  Create a zmstorectl object.
      #

      def initialize(*arguments)
        super(File.join(ZIMBRAPATH,'bin','zmstorectl'), ZIMBRAUSER, *arguments)
      end
  end

  class ZMSwatchctl < Action::RunCommand

      #
      #  Create a zmswatchctl object.
      #

      def initialize(*arguments)
        super(File.join(ZIMBRAPATH,'bin','zmswatchctl'), ZIMBRAUSER, *arguments)
      end
  end

  class ZMMylogpasswd < Action::RunCommand

      #
      #  Create a zmmylogpasswd object.
      #

      def initialize(*arguments)
        super(File.join(ZIMBRAPATH,'bin','zmmylogpasswd'), ZIMBRAUSER, *arguments)
      end
  end

  class ZMMysqlstatus < Action::RunCommandOnMailbox

      #
      #  Create a zmmysqlstatus object.
      #

      def initialize(*arguments)
        super(File.join(ZIMBRAPATH,'bin','zmmysqlstatus'), ZIMBRAUSER, *arguments)
      end
  end
  
  class ZMMypasswd < Action::RunCommandOnMailbox
   
     #
     #  Create a zmmypasswd object.
     #
   
     def initialize(*arguments)
       super(File.join(ZIMBRAPATH,'bin','zmmypasswd'), ZIMBRAUSER, *arguments)
     end
  end

  class ZMTlsctl < Action::RunCommandOnMailbox

      #
      #  Create a zmtlsctl object.
      #

      def initialize(*arguments)
        super(File.join(ZIMBRAPATH,'bin','zmtlsctl'), ZIMBRAUSER, *arguments)
      end
  end

  class ZMProxyctl < Action::RunCommandOnProxy

      #
      #  Create a zmproxyctl object.
      #

      def initialize(*arguments)
        super(File.join(ZIMBRAPATH,'bin','zmproxyctl'), ZIMBRAUSER, *arguments)
      end
  end

  class ZMMemcachedctl < Action::RunCommandOnMemcached

      #
      #  Create a zmproxyctl object.
      #

      def initialize(*arguments)
        super(File.join(ZIMBRAPATH,'bin','zmmemcachedctl'), ZIMBRAUSER, *arguments)
      end
  end

  class ZMNginxctl < Action::RunCommandOnProxy

      #
      #  Create a zmproxyctl object.
      #

      def initialize(*arguments)
        super(File.join(ZIMBRAPATH,'bin','zmnginxctl'), ZIMBRAUSER, *arguments)
      end
  end
   
  class ZMMilterctl < Action::RunCommandOnMta
  
    #
    #  Create a ZMMilterctl object.
    # 
      
    def initialize(*arguments)
      super(File.join(ZIMBRAPATH,'bin','zmmilterctl'), ZIMBRAUSER, *arguments)
    end  
  end  

end

if $0 == __FILE__
  require 'test/unit'
  module Action
    #
    # Unit test case for ZMAmavisd object
    class ZMAmavisdTest < Test::Unit::TestCase
      def testRun
        testObject = Action::ZMAmavisd.new('status')
        testObject.run
        assert_match(/amavisd is running/, testObject.response)
      end
    end

    # 
    # Unit test case for ZMMilterctl object
    class ZMMilterctlTest < Test::Unit::TestCase
      def test_run
        testObject = Action::ZMMilterctl.new('help')
        testObject.run
        assert_match(/zmmilterctl start\|stop\|restart\|reload\|refresh\|status/, testObject.response)        
      end
    end
  end
end


