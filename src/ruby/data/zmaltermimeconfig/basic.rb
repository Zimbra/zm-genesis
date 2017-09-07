#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2010 Vmware Zimbra
#
# Test zmaltermimeconfig
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
require "action/zmaltermimeconfig"
require "action/sendmail.rb"
require "action/zmamavisd.rb"

include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmaltermimeconfig"

name = File.expand_path(__FILE__).sub(/.*?(data\/)(genesis\/)?(zm)?/, 'zm').sub('.rb', '').gsub(/\/|\(|\)/, '') + Time.now.to_i.to_s

testAccount1 = Model::TARGETHOST.cUser(name + '1', Model::DEFAULTPASSWORD)
admin = Model::TARGETHOST.cUser("admin", Model::DEFAULTPASSWORD)

plainEmail = <<EOF.gsub(/\n/, "\r\n").gsub(/REPLACETO/, testAccount1.name).gsub(/REPLACEFROM/, admin.name)
Subject: hello plain
From: REPLACEFROM
To: REPLACETO
hello world
EOF

htmlEmail = <<EOF.gsub(/\n/, "\r\n").gsub(/REPLACETO/, testAccount1.name).gsub(/REPLACEFROM/, admin.name)
Subject: hello html
From:REPLACEFROM
To: REPLACETO
MIME-Version: 1.0
Content-type: text/html
<html>
<b>hello world</b>
</html>
EOF

zimbraDomainMandatoryMailSignatureText1 = "PlainDisclaimer"
zimbraDomainMandatoryMailSignatureHTML1 = "HTMLDisclaimer"
zimbraDomainMandatoryMailSignatureText2 = 'Plain\:disclaimerwith\,and\;'
zimbraDomainMandatoryMailSignatureHTML2 = 'HTML\:disclaimerwith\,and\;'
usage = [Regexp.escape('Usage: /opt/zimbra/libexec/zmaltermimeconfig [-h] [-f] [-v] [-d <domain>] [-e <domain>]'),
         Regexp.escape('-h|--help: print this usage statement.'),
         Regexp.escape('-d|--disable <domain>: Disable domain-specific disclaimer for domain <domain>.'),
         Regexp.escape('-e|--enable <domain>: Enable domain-specific disclaimer for domain <domain>.'),
         Regexp.escape('-f|--force: Force the rename, bypassing safety checks.'),
         Regexp.escape('-v|--verbose: Set the verbosity level.')
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

  ['h', 'H', '-help'].map do |x|
    v(ZMAltermimeconfig.new('-' + x)) do |mcaller,data|
      mcaller.pass = data[0] != 0 &&
                     data[1].split(/\n/).select {|w| w !~ /^\s*$/}.size == usage.size &&
                     data[1].split(/\n/).select {|w| w !~ /(#{usage.join('|')}|^$)/}.empty?
    end
  end,

  ([('a'..'z'),('A'..'Z')].map{|i| i.to_a}.flatten - ['d', 'D', 'e', 'E', 'h', 'H', 'f', 'F', 'v', 'V']).map do |x|
    v(ZMAltermimeconfig.new('-' + x)) do |mcaller,data|
      usage1 = [Regexp.escape('Unknown option: ' + x.downcase)] + usage
      mcaller.pass = data[0] != 0 &&
                     data[1].split(/\n/).select {|w| w !~ /^\s*$/}.size == usage1.size &&
                     data[1].split(/\n/).select {|w| w !~ /(#{usage1.join('|')}|^$)/}.empty?
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {'zmaltermimeconfig unknown option' => {"IS"=>data[1] + data[2], "SB"=>'Unknown option: ' + x.downcase}}
      end
    end
  end,

  v(ZMAltermimeconfig.new('-f')) do |mcaller,data|
    mcaller.pass = data[0] == 0 && data[1].empty?
  end,

  v(ZMAltermimeconfig.new('-v')) do |mcaller,data|
    mcaller.pass = data[0] == 0 && data[1].empty?
  end,

  v(ZMAltermimeconfig.new('-v+')) do |mcaller,data|
    mcaller.pass = data[0] != 0 && data[1].include?("Unknown option: v+")
  end,
    
  v(ZMAltermimeconfig.new('-d')) do |mcaller,data|
    mcaller.pass = data[0] != 0 && data[1].include?("Option d requires an argument")
  end,
    
  v(ZMAltermimeconfig.new('-e')) do |mcaller,data|
    mcaller.pass = data[0] != 0 && data[1].include?("Option e requires an argument")
  end,

  v(ZMProv.new('mcf', 'zimbraDomainMandatoryMailSignatureEnabled', 'TRUE')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].empty?
  end,

  v(ZMProv.new('mcf', 'zimbraDomainMandatoryMailSignatureText', zimbraDomainMandatoryMailSignatureText1)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?("Warn: attribute zimbraDomainMandatoryMailSignatureText has been deprecated since 8.5.0")
  end,

  v(ZMProv.new('mcf', 'zimbraDomainMandatoryMailSignatureHTML', zimbraDomainMandatoryMailSignatureHTML1)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?("Warn: attribute zimbraDomainMandatoryMailSignatureHTML has been deprecated since 8.5.0")
  end,
    
  v(ZMProv.new('md', mDomain = testAccount1.name[/.*@(.*)/, 1], 'zimbraAmavisDomainDisclaimerText', zimbraDomainMandatoryMailSignatureText1)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].empty?
  end,

  v(ZMProv.new('md', mDomain, 'zimbraAmavisDomainDisclaimerHTML', zimbraDomainMandatoryMailSignatureHTML1)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].empty?
  end,
    
  v(ZMAltermimeconfig.new('-e', mDomain)) do |mcaller,data|
    mcaller.pass = data[0] == 0 && data[1] =~ /Enabled disclaimers for domain: .*\nGenerating disclaimers for domain .*/
  end,

  CreateAccount.new(testAccount1.name, testAccount1.password),

  v(ZMAltermimeconfig.new()) do |mcaller,data|
    mcaller.pass = data[0] == 0 && data[1] == "Generating disclaimers for domain #{mDomain}.\n"
  end,

  # "zmamavisdctl restart" is required.
  v(ZMAmavisd.new('restart'), 240) do |mcaller, data|
    mcaller.pass = (data[0] == 0)
  end,

  SendMail.new(testAccount1.name, plainEmail),
  SendMail.new(testAccount1.name, htmlEmail),

  v(CSearch.new('-m', testAccount1.name, '-q', 'in:Inbox')) do |mcaller, data|
    mcaller.pass = data[0] == 0 &&
                   data[1].include?(zimbraDomainMandatoryMailSignatureText1) &&
                   data[1].include?(zimbraDomainMandatoryMailSignatureHTML1)
  end,

  v(ZMProv.new('mcf', 'zimbraDomainMandatoryMailSignatureEnabled', 'FALSE')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].empty?
  end,

  v(ZMAltermimeconfig.new()) do |mcaller,data|
    mcaller.pass = data[0] == 0 && data[1].empty?
  end,

  v(ZMAmavisd.new('restart'), 240) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
    
  #no zimbra_home references
  v(RunCommand.new('cat', Command::ZIMBRAUSER, ZMAltermimeconfig.new().to_str.split(/\s*:\s*/).last.strip)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].split(/\n/).select{|w| w =~ /.*{zimbra_home}.*/}.empty?
  end,
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
