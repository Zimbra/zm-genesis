#!/bin/env ruby -w
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
#
# Part of the command class structure, This is the interface to zmlicense commands
#

if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end
require 'action/runcommand'
require 'action/stafsystem'
require 'tempfile'
require 'model/testbed'
require 'action/zmprov'
require 'action/zmlocalconfig'


module Action # :nodoc
  
  # some global constants
  LICENSESERVER = 'zimbra-stage-license-vip.zimbra.com' unless defined?(LICENSESERVER)
  LICENSESERVICE = 'zimbraLicensePortal/QA/LKManager' unless defined?(LICENSESERVICE)
  ACTIVATIONSERVICE = 'zimbraLicensePortal/public/activation' unless defined?(ACTIVATIONSERVICE)
  LICENSETMPDIR = File.join(Command::ZIMBRAPATH, 'data', 'tmp') unless defined?(LICENSETMPDIR)

  #
  # Perform zmlicense action. This will call zmlicence with arbitrary arguments
  #
  class ZMLicense < Action::RunCommandOnMailbox

    #
    #  Create a zmlicense object
    #

    def initialize(*arguments)
      super(File.join(ZIMBRAPATH,'bin','zmlicense'), USER_ROOT, *arguments)
    end
  end
  
  #
  # Service actions with license.
  #
  
  # generates test license file and saves it to LICENSETMPDIR directory 
  class GetLicense < Action::RunCommand
    def initialize(filename = 'license.xml', version = '2.1', *args)
      @filename = filename
      @version = version
      super('/bin/env',Command::ZIMBRAUSER,'wget', '--no-proxy',
            '-O', File.join(Action::LICENSETMPDIR, @filename),
            "http://#{Action::LICENSESERVER}/#{Action::LICENSESERVICE}",
            "--post-data=\"#{Hash["ver", @version, *args].to_a.collect {|w| w.join('=')}.join('&')}\"")
    end
  end
  
  # generates activation file in LICENSETMPDIR directory 
  class GetActivation < Action::Command
    def initialize(filename = 'activation.xml')
      @filename = filename
      super()
    end
    
    def run
      mResult = ZMLicense.new('-p').run
      mLicense = Hash[*mResult[1].split("\n").compact.select {|w| w =~ /\S+=\S+/}.collect{|w| w.split('=')}.flatten]
      mResult = ZMSoap.new('-z', 'GetVersionInfoRequest').run
      mVersion = mResult[1][/\s+version="([^"]+)/, 1][/(.*)\.[^.]+$/, 1]
      mFingerprint = ZMLicense.new('-f').run[1].strip
      @runner = RunCommand.new('/bin/env',Command::ZIMBRAUSER,'wget', '--no-proxy',
            '-O', File.join(Action::LICENSETMPDIR, @filename),
            "http://#{Action::LICENSESERVER}/#{Action::ACTIVATIONSERVICE}",
            "--post-data=\"#{Hash['action', 'getActivation',
                                  'version', mVersion,
                                  'licenseId', mLicense['LicenseId'],
                                  'fingerprint', mFingerprint
                                 ].to_a.collect {|w| w.join('=')}.join('&')}\"")
      @runner.run
    end
  end
  
  # this class allows to calculate current number of accounts,
  # which might be useful for requesting custom license
  class CountAccounts
    @@currentAllAccounts = 0
    @@currentArchAccounts = 0
    @@currentUserAccounts = 0
    
    def self.getAllAccounts
      if @@currentAllAccounts == 0 then countAccounts end
      @@currentAllAccounts
    end
    
    def self.getArchAccounts
      if @@currentAllAccounts == 0 then countAccounts end
      @@currentArchAccounts
    end
    
    def self.getUserAccounts
      if @@currentAllAccounts == 0 then countAccounts end
      @@currentUserAccounts
    end

    def self.countAccounts
      
      @@currentAllAccounts = ZMProv.new('-l','gaa','|', 'wc', '-l').run[1].to_i
      @@currentArchAccounts = ZMProv.new('sa', "amavisArchiveQuarantineTo=*", '|', 'wc', '-l').run[1].to_i
      
      data = ZMProv.new('-l', 'gaa').run[1]
      data = data[/Data\s+:(.*?)\s*\}/m, 1] if(data =~ /Data\s+:/)
      @@currentUserAccounts = @@currentAllAccounts -
        data.split(/\n/).select{|w| w =~ /((spam|ham|wiki|virus-quarantine)\..*|mboxsearch|m)@#{Model::TARGETHOST}/}.length
    end
    
  end
  
  # deletes licence from LDAP
  class RemoveLicense < Action::Command
    
    def initialize
      super()
      @removeLicense = "#{Action::LICENSETMPDIR}/removeLicense.ldif"
      @message = <<EOF.gsub(/\n/, "\\n")
dn: cn=config,cn=zimbra
changetype: modify
delete: zimbraNetworkLicense
EOF
      self.timeOut = 120
    end
    
    def run
      mResult = RunCommandOnMailbox.new('echo', Command::ZIMBRAUSER, '-e', "\"#{@message}\"", '|',
                               File.join(Command::ZIMBRACOMMON, 'bin', 'ldapmodify'),
                               '-H', ZMLocalconfig.new('-m', 'nokey', 'ldap_url').run[1].chomp, 
                               '-x', '-D', '"cn=config"',
                               '-w', ZMLocalconfig.new('-s', '-m', 'nokey', 'ldap_root_password').run[1].chomp).run
      ZMProv.new('fc','license').run
      mResult
    end
								 
  end
end

if $0 == __FILE__
  require 'test/unit'
  module Action
    #
    # Unit test case for ZMLicense object
    class ZMLicenseTest < Test::Unit::TestCase
      def testRun
        testObject = Action::ZMLicense.new('-h')
        testObject.run
        assert(testObject.response.include?("help"))
      end
      def testConstants
        assert(Action::LICENSESERVER)
        assert(Action::LICENSESERVICE)
        assert(Action::LICENSETMPDIR)
      end
      def testDefaultGetLicense
        testObject = Action::GetLicense.new
        #puts testObject.to_str
        testObject.run
        assert(File.file?('/opt/zimbra/conf/license.xml'))
        assert(File.read('/opt/zimbra/conf/license.xml').include?('item name="InstallType" value="trial"') )
      end
      def testCustomGetLicense
        testObject = GetLicense.new('custom.xml', 'regular', 'AccountsLimit', 55, 'ArchivingAccountsLimit', '23',
                                    'ValidFrom', '01/01/2010', 'ValidUntil', '01/01/2011')
        #puts testObject.to_str
        testObject.run
        assert(File.file?('/opt/zimbra/conf/custom.xml'))
        testFile = File.read('/opt/zimbra/conf/custom.xml')
        assert(testFile.include?('item name="InstallType" value="regular"') )
        assert(testFile.include?('item name="AccountsLimit" value="55"') )
        assert(testFile.include?('item name="ArchivingAccountsLimit" value="23"') )
        assert(testFile.include?('item name="ValidFrom" value="20091230') )
        assert(testFile.include?('item name="ValidUntil" value="20110103') )
      end
      def testCountAccounts
        assert(CountAccounts.getAllAccounts > 0)
      end

    end
  end
end


