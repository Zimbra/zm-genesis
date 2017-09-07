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
# Test zmstatctl star, stop, reload
#
#if($0 == __FILE__)
#  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
#end

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "action/command"
require "action/clean"
require "action/block"
require "action/zmprov"
require "action/verify"
require "action/runcommand"
require "model"
require "action/zmcertmgr"
require "action/zmcontrol"
require "action/zmlocalconfig"
require 'openssl'


include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmcertmgr"
expected = ["** Recreating /opt/zimbra/ssl/zimbra/ca/zmssl.cnf",
            "** Creating CA with existing private key /opt/zimbra/ssl/zimbra/ca/ca.key"] # Bug 103808
mKeystore = ZMLocal.new('-x', 'mailboxd_keystore').run.split(/\s+/)[-1]
mPassword = ZMLocalconfig.new('-s', '-m nokey', 'mailboxd_keystore_password').run
mPassword[0] = 1 if mPassword[1] =~ /Warning:/

digest =  [Regexp.escape('ripemd160, sha, sha1, sha224, sha384, sha512'),
]

#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [
  # help message
  #if mCfg.getServersRunning('store').include?(Model::TARGETHOST.to_s)
  ['-h', '--help'].map do |x|
    v(ZMCertmgr.new(x)) do |mcaller,data|
      mcaller.pass = data[0] == 0 && data[1].include?("Usage:") 
    end
  end,

  [''].map do |x|
    v(ZMCertmgr.new(x)) do |mcaller,data|
      mcaller.pass = data[0] != 0 && data[1].include?('zmcertmgr: a command must be specified')
    end
  end,
  
  digest.last.split(/,\\\s/).map do |x|
  [
    v(ZMCertmgr.new('createcsr', 'self', '-new', '-digest', x)) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1].include?('Generating a server CSR') &&
                     !data[1].include?('WARNING: Unknown digest method:')
    end,
    
    v(cb("csr #{x} check") do
      mResult = OpenSSL::X509::Request.new File.read File.join(Command::ZIMBRAPATH, 'ssl', 'zimbra', 'server', 'server.csr')
    end) do |mcaller, data|
      mcaller.pass = data.signature_algorithm =~ /#{x}WithRSA(Encryption)?/ &&
                     data.to_text =~ /Public[ -]Key: \(2048 bit\)/
    end,
  ]
  end,
  
  digest.last.split(/,\\\s/).map do |x|
  [
    v(ZMCertmgr.new('createcrt','-new', '-digest', x)) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1].include?('** Signing cert request /opt/zimbra/ssl/zimbra/server/server.csr')
    end,
    
    v(cb("crt #{x} check") do
      mResult = OpenSSL::X509::Certificate.new File.read File.join(Command::ZIMBRAPATH, 'ssl', 'zimbra', 'server', 'server.crt')
    end) do |mcaller, data|
      mcaller.pass = data.signature_algorithm =~ /#{x}WithRSA(Encryption)?/ &&
                     data.to_text =~ /Public[ -]Key: \(2048 bit\)/
    end,
    
    v(ZMCertmgr.new('deploycrt','self')) do |mcaller, data|
      mcaller.pass = data[0] == 0 #&& data[1].include?('** Signing cert request /opt/zimbra/ssl/zimbra/server/server.csr...done.')
    end,
    
    RunCommand.new('ls', 'root', File.join(Command::ZIMBRAPATH, 'conf', '*.crt')).run[1].split.map do |y|
      v(cb("#{y} #{x} check") do
        mResult = OpenSSL::X509::Certificate.new File.read y
      end) do |mcaller, data|
        mcaller.pass = data.signature_algorithm =~ /#{x}WithRSA(Encryption)?/ &&
                       data.to_text =~ /Public[ -]Key: \(2048 bit\)/
      end
    end
  ]
  end,
  
  v(ZMCertmgr.new('createcsr', 'self', '-new')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('Generating a server CSR') &&
                   !data[1].include?('WARNING: Unknown digest method:')
  end,
  
  v(cb("csr default check") do
    mResult = OpenSSL::X509::Request.new File.read File.join(Command::ZIMBRAPATH, 'ssl', 'zimbra', 'server', 'server.csr')
  end) do |mcaller, data|
    mcaller.pass = data.signature_algorithm =~ /sha256WithRSAEncryption/
  end,

  v(ZMCertmgr.new('createcsr', 'self', '-new', '-digest', 'invalid')) do |mcaller, data|
    mcaller.pass = data[0] == 1 && data[1].include?('ERROR: unknown digest method \'invalid\'')
  end,

  v(cb("csr default to sha256") do
    mResult = OpenSSL::X509::Request.new File.read File.join(Command::ZIMBRAPATH, 'ssl', 'zimbra', 'server', 'server.csr')
  end) do |mcaller, data|
    mcaller.pass = data.signature_algorithm =~ /sha256WithRSAEncryption/
  end,

# Test Single-Node Self-Signed Certificate
#
# Begin by generating a new Certificate Authority (CA).
#
#

  digest.last.split(/,\\\s/).map do |x|
  [
    v(ZMCertmgr.new('createca','-new', '-digest', x)) do |mcaller, data|
      mcaller.pass = data[0] == 0 && (expected - data[1].split(/\n+/)).empty?
    end,
    
    v(cb("ca digest #{x} check") do
      mResult = OpenSSL::X509::Certificate.new File.read File.join(Command::ZIMBRAPATH, 'ssl', 'zimbra', 'ca', 'ca.pem')
    end) do |mcaller, data|
      mcaller.pass = data.signature_algorithm =~ /#{x}WithRSA(Encryption)?/ &&
                     data.to_text =~ /Public[ -]Key: \(2048 bit\)/
    end
  ]
  end,
  
  #TODO: createca [-new] [-keysize 2048] [-subject subject]
  
  v(ZMCertmgr.new('createca','-new')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && (expected - data[1].split(/\n+/)).empty?
  end,
  
  v(cb("ca default check") do
    mResult = OpenSSL::X509::Certificate.new File.read File.join(Command::ZIMBRAPATH, 'ssl', 'zimbra', 'ca', 'ca.pem')
  end) do |mcaller, data|
    mcaller.pass = data.signature_algorithm =~ /sha256WithRSAEncryption/
  end,

#
# Then generate a certificate signed by the CA that expires in 365 days and tests subjectAltNames functionality .
#
# zmcertmgr createcrt -new -days 365 wihout nodefaultsubjectaltnames option
  v(ZMCertmgr.new('createcrt','-new','-days','365','-subjectAltNames','host1.example.com,host2.example.com')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('Signing cert request')
  end,
#
# Next deploy the certificate.
#
# zmcertmgr deploycrt self
  v(ZMCertmgr.new('deploycrt','self')) do |mcaller, data|
    mcaller.pass = data[0] == 0 &&
                   data[1] =~ /Creating keystore \'#{mKeystore}\'/
                   data[1] =~ /Copying CA to #{Command::ZIMBRAPATH}.*/
  end,
#
# To finish, verify the certificate was deployed to all the services.
#
# zmcertmgr viewdeployedcrt
    
 v(ZMCertmgr.new('viewdeployedcrt ldap')) do |mcaller, data|
   mcaller.pass = (data[0] == 0) && data[1].include?("subject= /OU=Zimbra Collaboration Server/CN=#{Model::TARGETHOST}") &&
                                     data[1].include?("issuer= /O=CA/OU=Zimbra Collaboration Server/CN=#{Model::TARGETHOST}")&& # Bug 103808,103968
                                     data[1].include?("SubjectAltName="+Model::TARGETHOST+", host1.example.com, host2.example.com")#Bug 104327
 end,
  
 v(ZMCertmgr.new('viewdeployedcrt mailboxd')) do |mcaller, data|
   mcaller.pass = (data[0] == 0) && data[1].include?("subject= /OU=Zimbra Collaboration Server/CN=#{Model::TARGETHOST}") &&
                                     data[1].include?("issuer= /O=CA/OU=Zimbra Collaboration Server/CN=#{Model::TARGETHOST}")&& # Bug 103808,103968
                                     data[1].include?("SubjectAltName="+Model::TARGETHOST+", host1.example.com, host2.example.com")#Bug 104327
 end,  
  
 v(ZMCertmgr.new('viewdeployedcrt proxy')) do |mcaller, data|
   mcaller.pass = (data[0] == 0) && data[1].include?("subject= /OU=Zimbra Collaboration Server/CN=#{Model::TARGETHOST}") &&
                                     data[1].include?("issuer= /O=CA/OU=Zimbra Collaboration Server/CN=#{Model::TARGETHOST}")&& # Bug 103808,103968
                                     data[1].include?("SubjectAltName="+Model::TARGETHOST+", host1.example.com, host2.example.com")#Bug 104327
 end,
  
 v(ZMCertmgr.new('viewdeployedcrt mta')) do |mcaller, data|
   mcaller.pass = (data[0] == 0) && data[1].include?("subject= /OU=Zimbra Collaboration Server/CN=#{Model::TARGETHOST}") &&
                                     data[1].include?("issuer= /O=CA/OU=Zimbra Collaboration Server/CN=#{Model::TARGETHOST}")&& # Bug 103808,103968
                                     data[1].include?("SubjectAltName="+Model::TARGETHOST+", host1.example.com, host2.example.com")#Bug 104327
 end,  

 
# zmcertmgr createcrt -new -days 365, Bug 102741  "zmcertmgr createcrt" is ignoring subject line, hence added explicit subject while creating certificate 
  v(ZMCertmgr.new('createcrt','-new','-days','365','-subjectAltNames','host1.example.com,host2.example.com','-noDefaultSubjectAltName','-subject','"/C=US/ST=TX/L=Houston/O=InTelligent/OU=MKT/CN='+Model::TARGETHOST+'"')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('Signing cert request')
  end,
#
# Next deploy the certificate.
#
# zmcertmgr deploycrt self
  v(ZMCertmgr.new('deploycrt','self')) do |mcaller, data|
    mcaller.pass = data[0] == 0 &&
                   data[1] =~ /Creating keystore \'#{mKeystore}\'/
                   data[1] =~ /Copying CA to #{Command::ZIMBRAPATH}.*/
  end,
#
# To finish, verify the certificate was deployed to all the services.
#
# zmcertmgr viewdeployedcrt
    
 v(ZMCertmgr.new('viewdeployedcrt ldap')) do |mcaller, data|
   mcaller.pass = (data[0] == 0) && data[1].include?("subject= /C=US/ST=TX/L=Houston/O=InTelligent/OU=MKT/CN=#{Model::TARGETHOST}") &&
                                     data[1].include?("issuer= /O=CA/OU=Zimbra Collaboration Server/CN=#{Model::TARGETHOST}")&& # Bug 103808,103968
                                     data[1].include?("SubjectAltName=host1.example.com, host2.example.com")#Bug 104327
 end,
  
 v(ZMCertmgr.new('viewdeployedcrt mailboxd')) do |mcaller, data|
   mcaller.pass = (data[0] == 0) && data[1].include?("subject= /C=US/ST=TX/L=Houston/O=InTelligent/OU=MKT/CN=#{Model::TARGETHOST}") &&
                                     data[1].include?("issuer= /O=CA/OU=Zimbra Collaboration Server/CN=#{Model::TARGETHOST}")&& # Bug 103808,103968
                                     data[1].include?("SubjectAltName=host1.example.com, host2.example.com")#Bug 104327
 end,  
  
 v(ZMCertmgr.new('viewdeployedcrt proxy')) do |mcaller, data|
   mcaller.pass = (data[0] == 0) && data[1].include?("subject= /C=US/ST=TX/L=Houston/O=InTelligent/OU=MKT/CN=#{Model::TARGETHOST}") &&
                                     data[1].include?("issuer= /O=CA/OU=Zimbra Collaboration Server/CN=#{Model::TARGETHOST}")&& # Bug 103808,103968
                                     data[1].include?("SubjectAltName=host1.example.com, host2.example.com")#Bug 104327
 end,
  
 v(ZMCertmgr.new('viewdeployedcrt mta')) do |mcaller, data|
   mcaller.pass = (data[0] == 0) && data[1].include?("subject= /C=US/ST=TX/L=Houston/O=InTelligent/OU=MKT/CN=#{Model::TARGETHOST}") &&
                                     data[1].include?("issuer= /O=CA/OU=Zimbra Collaboration Server/CN=#{Model::TARGETHOST}")&& # Bug 103808,103968
                                     data[1].include?("SubjectAltName=host1.example.com, host2.example.com")#Bug 104327
 end,  
   
### test other options
#
# zmcertmgr createca -new
  v(ZMCertmgr.new('createca','-new')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && (expected - data[1].split(/\n+/)).empty?
  end,

#
# Then generate a certificate signed by the CA that expires in 365 days.
#
# zmcertmgr createcrt -new -days 365
  v(ZMCertmgr.new('createcrt','-new','-days','365','-subject','"/C=US/ST=NC/L=Mayberry/O=Sales/OU=ZimbraCollaborationSuite/CN='+Model::TARGETHOST+ '"')) do |mcaller, data|
#  v(ZMCertmgr.new('createcrt','-new','-days','365')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('Signing cert request')
  end,

#
# Next deploy the certificate.
#
# zmcertmgr deploycrt self
  v(ZMCertmgr.new('deploycrt','self')) do |mcaller, data|
    mcaller.pass = data[0] == 0 &&
                   data[1] =~ /Creating keystore \'#{mKeystore}\'/
                   data[1] =~ /Copying CA to #{Command::ZIMBRAPATH}.*/
  end,
#
# To finish, verify the certificate was deployed to all the services.
#
# zmcertmgr viewdeployedcrt
  v(ZMCertmgr.new('viewdeployedcrt')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('mta:')
  end,

  v(ZMCertmgr.new('viewcsr','self')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('subject=')
  end,

#  v(ZMCertmgr.new('viewcsr','comm')) do |mcaller, data|
#    mcaller.pass = (data[0] == 0) && data[1].include?('subject=')
#  end,

  v(ZMCertmgr.new('verifycrt','self','/opt/zimbra/ssl/zimbra/server/server.key','/opt/zimbra/ssl/zimbra/server/server.crt')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('Valid certificate chain:')
  end,

  v(ZMCertmgr.new('verifycrt','self')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('Valid certificate chain:')
  end,
  
  #zmcertmgr uses zimbra provided openssl
  v(ZMCertmgr.new('verifycrt','self','-debug 10')) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1].split(/\n/).select {|w| w =~ /\bopenssl\b/}.select {|w| w !~ /#{File.join(Command::ZIMBRACOMMON, 'bin', 'openssl')}/}.empty?
      mcaller.suppressDump("Suppress dump, the result has #{data[1].split(/\n/).size} lines") if !mcaller.pass
  end,
  
#  v(RunCommand.new('grep', 'root', 'openssl', File.join(Command::ZIMBRAPATH, 'bin', 'zmcertmgr'))) do |mcaller, data|
#    mcaller.pass = data[0] == 0 && data[1].split(/\n/).select {|w| w !~ /(\becho\b|^#|then)/}.select {|w| w !~ /\$\{openssl\}/}.select {|w| w !~ /^\s+openssl=/}.empty?
#  end,

  v(ZMCertmgr.new('viewstagedcrt','self')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('')
  end,

  v(ZMCertmgr.new('viewstagedcrt','self','/opt/zimbra/ssl/zimbra/server/server.crt')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('')
  end,

  v(ZMCertmgr.new('viewdeployedcrt')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('ldap:')&& data[1].include?('mta:')&& data[1].include?('proxy:')&& data[1].include?('mailboxd:')
  end,

  v(ZMCertmgr.new('viewdeployedcrt','all')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('ldap:')&& data[1].include?('mta:')&& data[1].include?('proxy:')&& data[1].include?('mailboxd:')
  end,

  v(ZMCertmgr.new('viewdeployedcrt','ldap')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('ldap:')
  end,

  v(ZMCertmgr.new('viewdeployedcrt','mta')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('mta:')
  end,

  v(ZMCertmgr.new('viewdeployedcrt','proxy')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('proxy:')
  end,

  v(ZMCertmgr.new('viewdeployedcrt','mailboxd')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('mailboxd:')
  end,

  v(ZMCertmgr.new('deployca')) do |mcaller, data|
    mcaller.pass = data[0] == 0 &&
                   data[1] =~ /Copying CA to #{Command::ZIMBRAPATH}.*/
  end,
  
  v(ZMCertmgr.new('savecrt','self')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  
  ZMControl.new('restart'),
  
  v(ZMCertmgr.new) do |mcaller, data|
    mcaller.pass = (data[0] == 1) && data[1].include?('Usage') && !data[1].include?('Exception')
  end,

  v(ZMCertmgr.new('-h')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('Usage:')&& !data[1].include?('Exception')
  end,

  v(ZMCertmgr.new('--help')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('Usage:')&& !data[1].include?('Exception')
  end,

  v((cb("test", 600) do
    data = RunCommand.new('/opt/zimbra/bin/zmcertmgr viewdeployedcrt ldap','root').run
  end)) do |mcaller, data|
    mcaller.pass = (data[0] == 1) && data[1].include?('zmcertmgr: ERROR: no longer runs as root!') && !data[1].include?('Exception')
  end,

  v(ZMCertmgr.new('createcsr','comm','-new','-subject','"/C=US/ST=NC/L=Mayberry/O=Sales/OU=ZimbraCollaborationSuite/CN='+Model::TARGETHOST+ '"')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('Generating a server CSR')
  end,
  
  # change the password
  if mPassword[0] == 0
    v(ZMLocalconfig.new('-e', 'mailboxd_keystore_password=foo123')) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1].split.empty?
    end
  end,

  # /opt/zimbra/bin/zmcertmgr viewdeployedcrt mailboxd
  if mPassword[0] == 0
    v(ZMCertmgr.new('viewdeployedcrt','mailboxd')) do |mcaller, data|
      mcaller.pass = data[0] == 1 &&
                     data[1].include?('keytool error: java.io.IOException: Keystore was tampered with, or password was incorrect')
    end
  end,
  
  # /opt/zimbra/bin/zmcertmgr viewdeployedcrt ldap not affected
  if mPassword[0] == 0
    v(ZMCertmgr.new('viewdeployedcrt','ldap')) do |mcaller, data|
      mcaller.pass = data[0] == 0 &&
                     data[1].include?("subject= /C=US/ST=NC/L=Mayberry/O=Sales/OU=ZimbraCollaborationSuite/CN=#{Model::TARGETHOST}") &&
                     data[1].include?("issuer= /O=CA/OU=Zimbra Collaboration Server/CN=#{Model::TARGETHOST}") # Bug 103808,103968
                     

    end
  end,
  
  # restore mailboxd_keystore_password
  if mPassword[0] == 0
    ZMLocalconfig.new('-e', "mailboxd_keystore_password=#{mPassword[1]}")
  end,

  # back to normal
  if mPassword[0] == 0
    v(ZMCertmgr.new('viewdeployedcrt','mailboxd')) do |mcaller, data|
      mcaller.pass = data[0] == 0 && 
                     data[1].include?("subject= /C=US/ST=NC/L=Mayberry/O=Sales/OU=ZimbraCollaborationSuite/CN=#{Model::TARGETHOST}") &&
                     data[1].include?("issuer= /O=CA/OU=Zimbra Collaboration Server/CN=#{Model::TARGETHOST}") # Bug 103808,103968
    end
  end,
  
    

]
#
# Tear Down
#

current.teardown = [
  if mPassword[0] == 0
    ZMLocalconfig.new('-e', "mailboxd_keystore_password=#{mPassword[1]}")
  end
]



if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance
  Engine::Simple.new(Model::TestCase.instance).run
end
