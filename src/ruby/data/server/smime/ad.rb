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
# Test external(AD) SMIME certificate
#


if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "action/block"
require "action/command"
require "action/zmprov"
require "action/verify"
require "action/runcommand"
require "model"
require "action/zmsoap"
require 'openssl'

include Action


#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "smime external AD tests"

name = File.expand_path(__FILE__).sub(/.*?(data\/)(genesis\/)?(zm)?/, 'zm').sub('.rb', '').gsub(/\/|\(|\)/, '') + Time.now.to_i.to_s
domain = Model::Domain.new("smime.#{name}.com")
testAccount = domain.cUser(name)

#
# Setup
#
current.setup = [

]
#
# Execution
#
current.action = [
  ZMProv.new('cd', domain.name),

  v(ZMProv.new('mdsc', domain.name, 'adconfig1',
               'zimbraSMIMELdapAttribute', 'userCertificate',
               'zimbraSMIMELdapBindDn', "\"administrator@zimbraqa.com\"",
               'zimbraSMIMELdapBindPassword', 'liquidsys',
               'zimbraSMIMELdapFilter', "\"(mail=%n)\"",
               'zimbraSMIMELdapSearchBase', "\"OU=CommonUsers,DC=zimbraqa,DC=com\"",
               'zimbraSMIMELdapURL', "\"ldap://zqa-003.eng.vmware.com:3268\"")) do |mcaller, data|
   mcaller.pass = data[0] == 0
  end,
  
  ZMProv.new('ca', testAccount.name, Model::DEFAULTPASSWORD),
  
  v(ZMSoap.new('-z',
               '-m', testAccount.name,
               '-t', 'account',
               'GetSMIMEPublicCertsRequest/email=smimeuser@zimbraqa.com ../store=LDAP')) do |mcaller, data|
    raw = data[1][/<cert\s+[^>]+>(.*)<\/cert/, 1].scan(/.{1,64}/) rescue []
    raw.unshift('-----BEGIN CERTIFICATE-----').push('-----END CERTIFICATE-----') if raw.select{|w| w =~ /CERTIFICATE----/}.empty?
    cert = OpenSSL::X509::Certificate.new(raw.join("\n")) rescue nil
    mcaller.pass = data[0] == 0 && !cert.nil? &&
                   cert.issuer.to_s == '/C=US/ST=California/L=Palo Alto/O=VMware/OU=Zimbra/CN=zimbra.com/emailAddress=support@qa.zimbra.com' &&
                   cert.subject.to_s == '/C=US/ST=California/L=QA City/O=QAWare/OU=ZimbraQA/CN=admin/emailAddress=admin@zimbraqa.com'
  end,
  
  # bug 76964
  v(ZMProv.new('-l', 'rd', domain.name, domain.name.to_s + 'new')) do |mcaller, data|
    mcaller.pass = data[0] == 0 &&
                   data[1].match(/domain .+ renamed to .+new/)
  end,

  v(ZMProv.new('gdsc', domain.name.to_s + 'new')) do |mcaller, data|
    mcaller.pass = data[0] == 0 &&
                   data[1].match(/name adconfig1/)    
  end
]
#
# Tear Down
#

current.teardown = [

]


if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance
  Engine::Simple.new(Model::TestCase.instance).run
end
