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
# Test basic SMIME
#

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
require "base64"
require 'model/deployment'

include Action


#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "smime server tests"

name = File.expand_path(__FILE__).sub(/.*?(data\/)(genesis\/)?(zm)?/, 'zm').sub('.rb', '').gsub(/\/|\(|\)/, '') + Time.now.to_i.to_s
domain = Model::Domain.new("smime.#{name}.com")
testAccount = domain.cUser(name)
certPath = File.join(Command::ZIMBRAPATH, 'ssl', 'zimbra', 'users')
openSSL = File.join(Command::ZIMBRACOMMON, 'bin', 'openssl')

#
# Setup
#
current.setup = [
  RunCommand.new('chmod', 'root', '-R', 'o+rx', File.dirname(certPath)),
]
#
# Execution
#
current.action = [
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
  v(RunCommand.new(openSSL, 'root', 'genrsa', '-out', File.join(certPath, 'users1.key'))) do |mcaller,data|
    mcaller.pass = data[0] == 0 && data[1].include?("Generating RSA private key")
  end,
  
  v(RunCommand.new(openSSL, 'root', 'genrsa', '-out', File.join(certPath, 'users2.key'))) do |mcaller,data|
    mcaller.pass = data[0] == 0 && data[1].include?("Generating RSA private key")
  end,
  
  v(ZMProv.new('cd', domain.name)) do |mcaller, data|
   mcaller.pass = data[0] == 0
  end,
  
  v(ZMProv.new('ca', testAccount.name, Model::DEFAULTPASSWORD,
               'userSMIMECertificate', File.join(certPath, 'users1.key'),
               'userSMIMECertificate', File.join(certPath, 'users2.key'))) do |mcaller, data| 
    mcaller.pass = data[0] == 0
  end,
  
  #ldap search ???

  v(cb("SMIME check") do
    mResult = ZMProv.new('syg', domain.name).run
    next [keys, ['users1.key', 'users2.key']] if mResult[0] != 0
    keys = mResult[1].split(/userSMIMECertificate::\s+/)[-2,2].collect {|k| Base64.decode64(k)}
    expected = [RunCommand.new('cat', Command::ZIMBRAUSER, File.join(certPath, 'users1.key')).run[1],
                RunCommand.new('cat', Command::ZIMBRAUSER, File.join(certPath, 'users2.key')).run[1]]
    [keys, expected]
  end) do |mcaller, data| 
    mcaller.pass = data[0].sort == data[1].sort
  end,
    
  Model::Deployment.getServersRunning('*').map do |x|
    v(cb("SMIME signer check") do
      mResult = RunCommand.new(File.join(Command::ZIMBRACOMMON, '/lib/jvm/openjdk-1.8.0_144-zimbra/', 'bin', 'jarsigner'), 'root',
                               '-verify', File.join(Command::ZIMBRAPATH, 'zimlets-deployed', 'com_zimbra_smime', 'com_zimbra_smime.jarx'), '2>&1', Model::Host.new(x)).run
    end) do |mcaller, data|
      mcaller.pass = data[0] && data[1].include?("jar verified.")
    end
  end,

]
#
# Tear Down
#

current.teardown = [
  RunCommand.new('chmod', 'root', '-R', 'o-rx', File.dirname(certPath)),
]


if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance
  Engine::Simple.new(Model::TestCase.instance).run
end
