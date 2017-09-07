#!/bin/env ruby
#
# = action/zmvolume.rb
#
# Copyright (c) 2012 VMWare
#
# Written & maintained by Virgil Stamatoiu
#
# Part of the command class structure.  This is the interface to open source license check
#
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end

require 'action/block'
require 'action/runcommand'
require 'action/verify'
 
module Action # :nodoc

  module OSLHelper
    
    def OSLHelper.licenseValidation(target)
      Block.new("OSL licenses check") do
        crt = nil
        case target
          when 'clamav', 'openldap', 'libevent'
            res = OSL.verifyLicense(target) do |ver, data|
              ver[/(\d+(\.\d+){2})/, 1] == (crt = data.first[/\b#{target}-(.*)/, 1])
            end
            res[-1] = crt
          when 'altermime'
            res = OSL.verifyLicense(target) do |ver, data|
              ver[/^(\d+\.\d+)/, 1] == (crt = data.first[/\b#{target}-(\d+\.\d+)/, 1])
            end
            res[-1] = crt
          when 'ews'
            res = [true, OSL::LegalApproved['ews']]
          when 'httpclient'
            target = 'apache-commons-httpclient'
            res = OSL.verifyLicense(target) do |ver, data|
              /#{crt = data.first[/\b#{target}-(.*)/, 1]}\b/ === ver
            end
            res[-1] = crt
          when 'jetty', 'servlet-api'
            target = 'jetty'
            res = OSL.verifyLicense(target) do |ver, data|
              /#{crt = data.first[/\b#{target}-(.*)/, 1]}\b/ === ver
            end
            res[-1] = crt
          when 'openssl', 'postfix'
            crt = nil
            res = OSL.verifyLicense(target) do |ver, data|
              ver == (crt = data.last[/\b#{target}-(.*)/, 1])
            end
            res[-1] = crt
          when 'perl-dbd-mysql', 'perl-lmdb'
            res = OSL.verifyLicense(target) do |ver, data|
              !(ver.gsub(/\./, '') =~ /#{(crt = data.first[/\b#{target}(\S+)?-(.*)/, 2]).gsub(/\./, '')}/).nil?
            end
            res[-1] = crt.gsub(/\.(\d+)$/, '\1')
          when 'perl-mail-spf'
            res = OSL.verifyLicense(target) do |ver, data|
              toks = ver.split(/\./).collect{|w| w.to_i}
              tmp = ver.split(/\./).collect {|w| w.to_i}.collect{|w| w.to_s}
              tmp.push('0') if tmp.size == 2
              tmp.join('.') == (crt = data.first[/\b#{target}-(.*)/, 1])
            end
            res[-1] = crt
          else
            res = OSL.verifyLicense(target)
        end
        res.unshift(res.first ? 0 : 1)
      end
    end

  end #end module

  class OSL < Action::RunCommand
  
    #
    #  Create OSL object.
    #
    @@licenses = nil
    
    def initialize(*arguments)
      @@file = File.join(ZIMBRAPATH,'docs','open_source_licenses.txt')
      super('cat', ZIMBRAUSER, @@file)
    end
    
    def run
      mResult = super
      mResult[1] = if RUBY_VERSION =~ /1\.8\.\d+/
                     require 'iconv'
                     Iconv.new("US-ASCII//TRANSLIT//IGNORE", "UTF8").iconv(mResult[1])
                   else
                     mResult[1].encode('US-ASCII', 'UTF-8', {:invalid => :replace, :undef => :replace, :replace => '??'})
                   end
      # retain only application layer licenses
      mResult[1].gsub!(/.*?PART\s+\d+\.\s+VIRTUAL APPLIANCE: APPLICATION LAYER[^\n]*\n/, '').strip if mResult[1] =~ /.*?PART\s+\d+\.\s+VIRTUAL APPLIANCE: APPLICATION LAYER[^\n]*\n/
      @@licenses = mResult[0] == 0 ? mResult[1].split(/\n/).select {|w| w =~ /^\s*>>>\s+/}.select {|w| w !~ /License/i}.collect {|w| w.strip}.uniq : []
    end
    
    def self.verifyLicense(target, &mblock)
      OSL.new.run if @@licenses.nil?
      return [false, 'undefined thirdparty - TODO: add to oslicense'] if !LegalApproved.has_key?(target) #should not get here
      return [false, "#{target} - license missing from #{@@file}"] if (license = @@licenses.select {|w| w =~ /\s+#{target}/}).size == 0
      ret = block_given? ? mblock.call(LegalApproved[target], license) : !(license.first[/\b#{target}-(.*)/, 1] =~ /#{Regexp.escape(LegalApproved[target])}/).nil?
      [ret, license.first[/#{target}-(.*)/, 1]]
    end
    
    def OSL::isRelease(host = Model::TARGETHOST.to_s)
      RunCommand.new('grep', 'root', 'zimbra-core', File.join(Command::ZIMBRAPATH, '.install_history'), Model::Host.new(host)).run[1].split(/\n/).last =~ /GA/
    end
    
    def self.licenses
      @@licenses
    end
    
    LegalApproved = {'altermime'               => '0.3.11',
                       'amavisd'                 => '2.10.1',
                        'apache-apr'              => '1.5.2',
                        'apache-apr-util'         => '1.5.4',
                        'apache-commons-httpclient' => '3.1',
                        'apache-helix'            => '0.6.1',
                        'apache-httpasyncclient'  => '4.0-beta3',
                        'apache-httpcomponents-core' => '4.2.2',
                        'apache-httpd'            => '2.4.20',
                        'apache-neethi'           => '3.0.2',
                        'clamav'                  => '0.99.2',
                        'apache-commons-codec'    => '1.7',
                         'apache-commons-net'             => '3.3',
                        'apache-commons-net'     => '3.3',
                        'curator'                 => '2.0.1',
                        'curl'                    => '7.49.1',
                        'apache-cxf'              => '2.7.18',
                        'cyrus-sasl-zimbra'       => '2.1.26',
                        # 'dspam'                   => '3.10.2',  #bug 97635
                        'ews'                     => 'ews_2010',
                        # 'google-perftools'        => ' 2.4',
                        'gperftools'        => '2.4',
                        'guava'                   => '13.0.1',
                        'heimdal'                 => '1.5.3',
                        'httpclient'              => '4.2.1',
                        'innotop'                 => '1.9.1',
                        # 'JavaPNS'                 => '2.2', #bug 97635
                        'javax.ws.rs-api'         => '2.0-m10',
                        'jcommon'                 => '1.0.21',             #bug 84589
                         'openjdk'                   => '1.8.0u144b01', #bug 97635
                        'jetty'                   => '9.3.5.v20151012',    #bug 101531
                        'jfreechart'              => '1.0.15',             #bug 84589
                        'libevent'                => '2.0.22-stable',      #bug 102486
                        'libtool'                 => '2.2.6b',
                        #'mariadb'                 => '1.1.8.0',
                        'memcached'               => '1.4.37',
                         'mysql'                   => '10.1.25',  # bug 97635
                        # 'mysql-connector-java'    => '5.1.29',             #bug 87428   # commented as per bug 97635
                        'mariadb-java-client'    => '1.1.8.0',       # bug 97635
                        'net-snmp'                => '5.7.3',
                        'nginx'                   => '1.7.1',
                        'noggit'                  => '0.7',
                        'objenesis'               => '2.1',
                        'opencsv'                 => '1.8',
  
                           'opendkim'                => '2.10.3',
                           'org.openid4java'         => '1.0.0',
                           'openldap'                => '2.4.44',
                           'openssl'                 => '1.0.2l',
                          # 'perl-crypt-ssleay'       => 'Can\'t locate',    #bug 97635
                           'perl-berkeleydb'         => '0.55',
                           'perl-dbd-mysql'          => '4.033',
                           'perl-filesys-df'         => '0.92',
                           'perl-ldap'               => '0.65',
                           'perl-lmdb'               => '0.07',
                           'perl-mail-spf'           => '2.009',
                          # 'perl-extutils-makemaker' => '7.04',   # bug 97635
                           'perl-net-cidr-lite'      => '0.21',
                           'perl-net-ssleay'         => '1.72',
                           'perl-zmq-constants'      => '1.04',
                           'perl-zmq-libzmq3'        => '1.19',
                           'pflogsumm'               => '1.1.5',
                           'php'                     => '5.6.31',
                           'postfix'                 => '3.1.1',
                           'rsync'                   => '3.1.2',
                           'sendmail'                => '8.15.2',
                           'servlet-api'             => '3.1.0',
                           'spamassassin'            => '3.4.1',
                           'spring-framework'        => '3.0.7',
                           'stax2'                   => '3.1.1',
                           'tinymce'                 => '4.2.6', #bug 101335
                           'tnef'                    => '1.8.0',
                           'unbound'                 => '1.5.9', #bug 101672
                           'unbound-ldap-sdk'        => '2.3.5',
                           'woodstox'                => '4.2.0',
                           'owasp'                   => '239',
                           'wsdl4j'                  => '1.6.3',
                           'xercesImpl'              => '2.9.1',

                           'xmlschema'               => '2.0.3',
                           'zeromq'                  => '4.1.4',
                           'zkclient'                => '0.1',
                           'zookeeper'               => '3.4.5',
                           'oauth'                  => '1.4',

                    }
    Modules = {'BerkeleyDB'          => 'perl-berkeleydb',
               'Crypt::SSLeay'       => 'perl-crypt-ssleay',
               'DBD::mysql'          => 'perl-dbd-mysql',
               #'ExtUtils::MakeMaker' => 'perl-extutils-makemaker',
               'Filesys::Df'         => 'perl-filesys-df',
               #'LMDB_File'           => 'perl-lmdb',
               'Mail::SPF'           => 'perl-mail-spf',
               'Net::CIDR::Lite'     => 'perl-net-cidr-lite',
               'Net::LDAP'           => 'perl-ldap',
               'Net::SSLeay'         => 'perl-net-ssleay',
               'ZMQ::Constants'      => 'perl-zmq-constants',
               'ZMQ::LibZMQ3'        => 'perl-zmq-libzmq3',
              }
  end

end

if $0 == __FILE__
  require 'test/unit'
  module Action
    #
    # Unit test cases
    class OSLTest < Test::Unit::TestCase
      def testRun
        testObject = Action::OSL.new
        assert(OSL.verifyLicense('foo') == false, 'license foo')
        assert(OSL::LegalApproved.instance_of?(Hash), 'not a Hash')
      end  
      
      def testOSLHelper
        assert(OSLHelper.licenseValidation('foo').run[1] == false, 'license foo passed')
      end
    end
  end
end
