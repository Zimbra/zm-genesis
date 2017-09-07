#!/usr/bin/ruby -w
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2007 Zimbra
#
#

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model" 
require "action/block"
require "action/runcommand" 
require "action/verify"
require 'rexml/document'
include REXML
#require "action/zmcontrol" 

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "imapproxy certs test"

include Action 


imapproxy = 'nginx'
certType = '.crt'
proxyInstalled = false
#
# Setup
#
current.setup = [
   
] 
#
# Execution
#


current.action = [
  v(RunCommand.new("/bin/cat", 'root', File.join(Command::ZIMBRAPATH, 'uninstall', 'config.xml'))) do |mcaller, data|
    iResult = data[1]
    if data[0] == 0
      #if(iResult =~ /Data\s+:/)
      #  iResult = (iResult)[/Data\s+:(.*?)\s*\}/m, 1]
      #end
      doc = Document.new iResult.slice(iResult.index('<?xml version'), iResult.index('</plan>') - iResult.index('<?xml version') + '</plan>'.length)
      doc.elements.each("/host") do
        |host|
        next if host.attributes['name'] != Model::TARGETHOST
        host.each_element_with_attribute('name', 'zimbra-proxy') { |e|
          proxyInstalled = true
        }
      end
    end
    mcaller.pass = true
  end,

  v(RunCommand.new(File.join('/usr/bin','openssl'), 'root', 
                             'verify',
                             '-CAfile', File.join(Command::ZIMBRAPATH, 'conf', 'ca', 'ca.pem'),
                             File.join(Command::ZIMBRAPATH, 'conf', imapproxy + certType))) do |mcaller, data|
    if !proxyInstalled
      data[0] = 0
      mResult = "OK"
    else
      data[0] = 1 if data[1] =~ /Error/
      iResult = data[1]
      if(iResult =~ /Data\s+:/)
        iResult = iResult[/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
      end
      mResult = iResult[/#{File.join(Command::ZIMBRAPATH, 'conf', imapproxy + certType)}:\s+(.*)/, 1]
    end
    mcaller.pass = data[0] == 0 && mResult == "OK"
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {File.join(Command::ZIMBRAPATH, 'conf', imapproxy + certType) => {"IS"=>mResult, "SB"=>"OK"}}
    end
  end,
  
  v(RunCommand.new(File.join('/usr/bin','openssl'), 'root', 
                             'rsa', '-noout', '-check',
                             '-in', File.join(Command::ZIMBRAPATH, 'conf', imapproxy + '.key'))) do |mcaller, data|
    if !proxyInstalled
      data[0] = 0
      mResult = "RSA key ok"
    else
      data[0] = 1 if data[1] =~ /Error/
      iResult = data[1]
      if(iResult =~ /Data\s+:/)
        iResult = iResult[/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
      end
      mResult = iResult.chomp
    end
    mcaller.pass = data[0] == 0 && mResult == "RSA key ok"
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {File.join(Command::ZIMBRAPATH, 'conf', imapproxy + '.key') => {"IS"=>mResult, "SB"=>"RSA key ok"}}
    end
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