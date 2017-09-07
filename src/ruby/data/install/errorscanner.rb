#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2007 Zimbra
# Check for errors in zmsetup/install log:
# - zmprov errors: usage:  modifyServer(ms) {name|id} [attr1 value1 [attr2 value2...]]
#                  zmprov [args] [cmd] [cmd-args ...]
# - gibberish messages
# - ldapmodify: modify operation type is missing at line


if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
mypath = 'data'
if($0 =~ /data\/genesis/)
  mypath += '/genesis'
end

require "model" 
require "action/block"
require "action/runcommand" 
require "action/verify"
require "#{mypath}/install/historyparser"
require "#{mypath}/install/utils"
require "action/zmlocalconfig"
require "action/buildparser"
require "#{mypath}/install/configparser"

#
# Global variable declaration
#


module Action
  
  class ErrorScanner < Action::Command
      #attr :filename, false
      #attr :attributes, false
      #attr :doc, false
        
      #
      # Objection creation
      # 
  #    def initialize(filename = File.join('.uninstall', 'config.xml'))
  #      super("cat", 'root', File.join(Command::ZIMBRAPATH,filename))
  #      @filename = File.join(Command::ZIMBRAPATH,filename)
  #    end
  
    isRelease = RunCommand.new('ls', 'root', File.join(Command::ZIMBRAPATH, '.uninstall', 'packages', 'zimbra-core*')).run[1] =~ /GA/
    mKeystore = (w = ZMLocal.new('mailboxd_keystore').run) =~ /Warning: null valued key/ ? '/opt/zimbra/mailboxd/etc/keystore' : w
    
    ERRORS = ['^usage:\s+.*',
              'Segmentation fault.*',
              '[\x0-\x8\xb\xc\xe-\x1f\x7f].*',
              'ldapmodify:\s+modify operation type is missing at line .*',
              '^BEGIN failed--compilation aborted.*',
              '^ERROR: service.INVALID_REQUEST \(invalid request.*',
              '^ERROR\s+\d+\s+\(\w{5}\)',
              'ssh-keygen:\s+.*:\s+no version information available',
              'ERROR: account.INVALID_ATTR_NAME.*',
              'ulimit: open files: cannot modify limit: Invalid argument',
              'Key for ' + Model::TARGETHOST + ' NOT FOUND',
              'cp: cannot stat .*(keystore|\/cron\/.*\/zimbra).: No such file or directory',
              'ch(own|mod): cannot access .*: No such file or directory',
              'chown: (too few arguments|missing operand after)',
              'sed: .* unknown command:',
              'hdiutil:\s+.*failed',
              '^eGrror\s+',
              '^Exception in thread\s+',
              '[sS]yntax error(\s+on line .*)?:.*',
              'slapadd: could not parse entry',
              'Zimlet \S+ being installed is of an older version',
              'Cannot add or update a child row: a foreign key constraint fails\s+.*',
              'sh:\s+\S+: command not found',
              '-(su|bash): line \d+:.*command not found',
              'Undefined subroutine &\S+(::\S+)* called at',
              "Can't locate .* in @INC",
              '.*: line \d+:.*missing `.*',
              "amavis.*DIE",
              "Unable to find expected .*\.\s+Found version .* instead",
              '.*invalid value for attributeType\s+.*',
              "/opt/zimbra/.*: No such file or directory",
              "Do you want to verify logger database integrity\?",
              "su: invalid option --",
              "ERROR: Invalid schedule:",
              "unary operator expected",
              "warning: not owned by root: /opt/zimbra",
              'com\.zimbra\.\S+Exception: zimbra\S+ value length\(\d+\) larger then max allowed: \d+',
              'zimlet - Unable to load zimlet handler for com_zimbra_.*$',
              '.*Unable to create temp file.*',
              'line \d+: syntax error',
              'error:[0-9A-F]+:PEM routines:',
              'ERROR: uninstall expected to delete zimbra startup script',
              'Error: No default configuration found',
              'Setting up syslog.conf\.{3}Failed',
              'df: no file systems processed',
              'Attempt to modify a deprecated attribute.*$',
              'Received new license from tms',
              '.*system failure: unable to modify attrs: LDAP error',
              'com.mysql.jdbc.exceptions.jdbc4.MySQLSyntaxErrorException: Table\s+.*',
              'Unknown option:',
              'Unable to restart \S*syslog\S* service.  Please do it manually.',
              'slapadd import failed',
              'Unknown config type \S+ for key.*',
              "java.util.MissingResourceException: Can't find resource for bundle java.util.PropertyResourceBundle",
              '.*Exception:\s+.*',
              '.+segfault.+',
              'error: Missing argument for option',
              'SSL connect attempt failed with unknown error',
              isRelease ? 'This is a Network Edition .* build and is not intended for production.' : nil,
              "#{mKeystore} didn't exist.",
              'zmconfigd.*: Hung threads detected',
              'defined\(@array\) is deprecated',
              '\/smtpd?\[\d+\]: fatal:\s+',
              'checksum error on',
              'zmconfigd\[\d+\]: Rewrite failed',
              'LDAPROOTPW=[^*]+',
              'LDAPZIMBRAPW=[^*]+',
              'LDAPPOSTPW=[^*]+',
              'LDAPREPPW=[^*]+',
              'LDAPAMAVISPW=[^*]+',
              'LDAPNGINXPW=[^*]+'
             ].compact unless defined?(ERRORS)
    
    #ERRORS << 'This is a Network Edition .* build and is not intended for production.' if isRelease
    
    #ERRORS << "#{mKeystore} didn't exist."
    
    EXCEPTS = ['^ERROR: service.INVALID_REQUEST \(invalid request:\s+port\s+(110|993|143|995).*',
               'hdiutil: detach failed - No such file or directory',
               'error reading information on service (ccsd|cman|fenced|rgmanager): No such file or directory',
               'java.io.FileNotFoundException: /opt/zimbra/data/tmp/libreoffice/conversion_cache/doc_lru.cache',
               'com.zimbra.cs.account.AccountServiceException: zimbraMtaRestriction value length\(\d+\) larger than max allowed: \d+',
               'warning: not owned by root: /opt/zimbra(/data)?/postfix',
               Utils::isUpgrade ? nil : "#{mKeystore} didn't exist.",
               Utils::isAppliance ? "192.168.1.0/24': -c: line 1: syntax error: unexpected end of file" : nil,
               Utils::isAppliance ? '.*\[74G\[ OK \]' : nil,
               isRelease ? nil : 'Attempt to modify a deprecated attribute:\s+zimbraInstalledSkin',
               BuildParser.instance.targetBuildId =~ /IRONMAIDEN-\d+/ || Utils::isUpgradeFrom('8.0.0.GA') ? 'kernel: .* opendkim\[\d+\]: segfault at 1f0' : nil
              ].compact unless defined?(EXCEPTS)
    #EXCEPTS << "#{mKeystore} didn't exist." if !Utils::isUpgrade()
    #EXCEPTS << "192.168.1.0/24': -c: line 1: syntax error: unexpected end of file" if Utils::isAppliance
    #EXCEPTS << '.*\[74G\[ OK \]' if Utils::isAppliance
    #EXCEPTS << 'Attempt to modify a deprecated attribute:\s+zimbraInstalledSkin' if !isRelease
    #EXCEPTS << 'kernel: .* opendkim\[\d+\]: segfault at 1f0' if BuildParser.instance.targetBuildId =~ /IRONMAIDEN-D(4|5)/ || Utils::isUpgradeFrom('8.0.0.GA')
              
    DUPLICATE_THRESHOLD = 20
  end
end

if $0 == __FILE__
  require 'test/unit'  
  include Action
  
   
  # Unit test cases for Proxy
  class ErrorScannerTest < Test::Unit::TestCase     
    def testNoArgument 
      testOne = ErrorScanner.new
      assert(!testOne.nil?)
      #testOne.run
      #assert(!testOne.isPackageInstalled('zimbra-core'))
      #assert(!testOne.hasOption('zimbra-ldap', 'LDAPPASS', 'test1234'))
    end
  end   
end