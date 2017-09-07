#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2011 Vmware Zimbra
#
# Test two-way SSL authentication
#
#if($0 == __FILE__)
#  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
#end

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "action/block"
require "action/command"
require "action/clean"
require "action/csearch" 
require "action/zmprov"
require "action/verify"
require "action/runcommand"
require "model"
require "action/zmldapanon"
require "action/zmcertmgr"
require "action/zmlocalconfig"
require "action/zmamavisd"

include Action


#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test client authentication"

name = File.expand_path(__FILE__).sub(/.*?(data\/)(genesis\/)?(zm)?/, 'zm').sub('.rb', '').gsub(/\/|\(|\)/, '') + Time.now.to_i.to_s
domain = Model::Domain.new("certauth.#{name}.com")
testAccount = domain.cUser(name)
certPath = File.join(Command::ZIMBRAPATH, 'ssl', 'zimbra', 'users')
openSSL = File.join(Command::ZIMBRACOMMON, 'bin', 'openssl')

#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [
  unless Model::TARGETHOST.proxy
  [
    v(RunCommand.new('mkdir', 'root', '-p', File.join(certPath, 'ca', 'newcerts'))) do |mcaller,data|
      mcaller.pass = data[0] == 0 && data[1].empty?
    end,
  
    v(RunCommand.new('touch', 'root', File.join(certPath, 'ca', 'index.txt'))) do |mcaller,data|
      mcaller.pass = data[0] == 0 && data[1].empty?
    end,
    
    cb("Create ssl config file") do
      rawMessage = IO.readlines(File.join(Command::ZIMBRAPATH, 'conf', 'zmssl.cnf'))
      #rawMessage = IO.readlines(File.join(Model::DATAPATH, 'email01', 'msg01.txt'))
      message = rawMessage.collect do |w|
                  w.gsub(/^(dir\s+=\s+)\S+(.*)$/, '\1' + File.join(certPath, 'ca') + '\2')
                end#.collect do |w|
                  #w.gsub(/Subject: \S+/, "Subject: #{testAccount.name}")
                #end.collect do |w|
                #  w.gsub(/From: \S+/, 'From: genesis@zimbra.com')
                #end
      File.open(File.join(certPath, 'qassl.cnf'), "w") do |file|
        file.puts message.join('')
      end
    end,
    
    v(RunCommand.new(openSSL, 'root', 'genrsa', '-out', File.join(certPath, 'ca.key'))) do |mcaller,data|
      mcaller.pass = data[0] == 0 && data[1].include?("Generating RSA private key")
    end,
    
    v(RunCommand.new(openSSL, 'root', 'req', '-new',
                     '-key', File.join(certPath, 'ca.key'),
                     '-out', File.join(certPath, 'ca.csr'),
                     '-subj', "\"/L=Palo Alto/O=VMWare/OU=Zimbra\"",
                     '-config', File.join(certPath, 'qassl.cnf'),
                     '-batch')) do |mcaller,data|
      mcaller.pass = data[0] == 0 && data[1].empty?
    end,
    
    v(RunCommand.new(openSSL, 'root', 'x509', '-req', '-days', 365,
                     '-in', File.join(certPath, 'ca.csr'),
                     '-out', File.join(certPath, 'ca.crt'),
                     '-signkey', File.join(certPath, 'ca.key'))) do |mcaller,data|
      mcaller.pass = data[0] == 0 && (['Signature ok', 'Getting Private key'] - data[1].split(/\n/)).empty?
    end,
    
    #Create a private key
    v(RunCommand.new(openSSL, 'root', 'genrsa', '-out', File.join(certPath, 'users.key'))) do |mcaller,data|
      mcaller.pass = data[0] == 0 && data[1].include?("Generating RSA private key")
    end,
    
    #Create a certificate request
    v(RunCommand.new(openSSL, 'root', 'req', '-new',
                     '-key', File.join(certPath, 'users.key'),
                     '-out', File.join(certPath, name + '.csr'),
                     '-subj', "\"/L=QA City/O=QAWare/OU=ZimbraQA/CN=#{name}/emailAddress=#{testAccount.to_s}\"",
                     '-config', File.join(certPath, 'qassl.cnf'),
                     '-batch')) do |mcaller,data|
      mcaller.pass = data[0] == 0 && data[1].empty?
    end,
  
    #Create and sign the user certificate
    v(cb("connection test") do
      if RunCommand.new('ls', 'root', File.join(certPath, '..', 'commercial', 'commercial.*')).run[0] != 0
        mKey = File.join(certPath, 'ca.key')
        mCrt = File.join(certPath, 'ca.crt')
      else
        mKey = File.join(certPath, '..', 'commercial', 'commercial.key')
        mCrt = File.join(certPath, '..', 'commercial', 'commercial.crt')
      end
      mResult = RunCommand.new(openSSL, 'root', 'ca',
                               '-keyfile', mKey,
                               '-cert', mCrt,
                               '-in', File.join(certPath, name + '.csr'),
                               '-out', File.join(certPath, name + '.crt'),
                               '-policy', 'policy_anything',
                               '-config', File.join(certPath, 'qassl.cnf'),
                               '-batch').run
    end) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1].include?('Data Base Updated')
    end,
  
=begin  
    v(ZMCertmgr.new('addcacert', File.join(certPath, 'ca.crt'))) do |mcaller,data|
      mcaller.pass = data[0] == 0 &&
                     ['** Importing certificate /opt/zimbra/ssl/zimbra/users/ca.crt to CACERTS as zcs-user-ca...done.',
                      '** NOTE: mailboxd must be restarted in order to use the imported certificate.'].sort == data[1].split(/\n/).sort
    end,
=end
    v(ZMTlsctl.new('both')) do |mcaller,data|
      mcaller.pass = (data[0] == 0) \
        && data[1].include?("Attempting to set ldap config zimbraMailMode both on host " + Model::TARGETHOST + "...done.") \
        && data[1].include?("Rewriting config files for cyrus-sasl, webxml, mailboxd, service, zimbraUI, and zimbraAdmin...done.")
    end,
    
    v(ZMProv.new('ms', Model::TARGETHOST,
                 'zimbraMailSSLClientCertPort', '9443',
                 'zimbraMailSSLClientCertMode', 'WantClientAuth')) do |mcaller,data|
      mcaller.pass = data[0] == 0 && data[1].empty?
    end,
    
    v(ZMProv.new('cd', domain.name,
                 'zimbraVirtualHostname', Model::TARGETHOST.to_s)) do |mcaller,data|
      mcaller.pass = data[0] == 0 #&& data[1].empty?
    end,
    
    CreateAccount.new(testAccount.name,Model::DEFAULTPASSWORD),
    
    v(ZMProv.new('mcf', 'zimbraMailSSLClientCertPrincipalMapLdapFilterEnabled', 'TRUE')) do |mcaller,data|
      mcaller.pass = data[0] == 0 && data[1].empty?
    end,
    
    v(ZMMailboxdctl.new('restart')) do |mcaller, data|
      mcaller.pass = data[0] == 0 && !data[1].include?('failed')
    end,
    
    ZMMailboxdctl.waitForJetty,
    
    v(cb("connection test") do
      if RunCommand.new('ls', 'root', File.join(certPath, '..', 'commercial', 'commercial.*')).run[0] != 0
        mCa = File.join(certPath, '..', 'ca', 'ca.pem')
      else
        mCa = File.join(certPath, '..', 'commercial', 'commercial_ca.crt')
      end
      mResult = RunCommand.new(openSSL, 'root', 's_client',
                               '-connect', Model::TARGETHOST.to_s + ':9443/certauth',
                               '-cert', File.join(certPath, name + '.crt'),
                               '-key', File.join(certPath, 'users.key'),
                               '-CAfile', mCa, '</dev/null'
                              ).run
    end) do |mcaller, data|
      mcaller.pass = data[1] =~ /Verify return code:\s+0\s+\(ok\)/
    end,
  ]
  end
]
#
# Tear Down
#

current.teardown = [
  ZMProv.new('da', testAccount.name),
  ZMProv.new('dd', domain.name)

]


if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance
  Engine::Simple.new(Model::TestCase.instance).run
end
