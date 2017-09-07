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
# Test zmsoap basic functions
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
require "action/zmsoap"
require 'action/zmcontrol'
require "model"
require 'json'


include Action

nNow = Time.now.to_i.to_s
usage = [Regexp.escape('usage: zmsoap [options] xpath1 [xpath2 xpath3 ...]'),
         Regexp.escape('-A,--admin-priv              Execute requests with admin privileges.'),
         Regexp.escape('-a,--admin <account-name>    Admin account name to authenticate as.'),
         Regexp.escape('   --auth <account-name>     Account name to authenticate as.  Defaults to'),
         Regexp.escape('                             account in -m.'),
         Regexp.escape('-f,--file <path>             Read request from file.  For JSON, the request'),
         Regexp.escape('                             pair should be the child of the root object.'),
         Regexp.escape('-h,--help                    Display this help message.'),
         Regexp.escape('   --jaxb                    Force use of JAXB to aid building request from'),
         Regexp.escape('                             command line.'),
         Regexp.escape('   --json                    Use JSON instead of XML. (Switches on --jaxb'),
         Regexp.escape('                             option by default).'),
         Regexp.escape('-m,--mailbox <account-name>  Send mail and account requests to this account.'),
         Regexp.escape('                             Also used for authentication if --auth, -a and -z'),
         Regexp.escape('                             are not specified.'),
         Regexp.escape("-n,--no-op                   Print the SOAP request only.  Don't send it."),
         Regexp.escape('   --no-jaxb                 Disallow use of JAXB to aid building request from'),
         Regexp.escape('                             command line.'),
         Regexp.escape('-p,--password <password>     Password.'),
         Regexp.escape('-P,--passfile <path>         Read password from file.'),
         #Regexp.escape('   --scratchcode <arg>       Scratch code for two-factor auth'),                         //Bug 100737
         Regexp.escape('   --select <xpath>          Select an element or attribute from the response.'),
         Regexp.escape('-t,--type <type>             SOAP request type:'),
         Regexp.escape('                             account,admin,im,mail,mobile,offline,voice.'),
         Regexp.escape('                             Default is admin, or mail if -m is specified.'),
         Regexp.escape('   --totp <arg>              TOTP token for two-factor auth'),
         Regexp.escape('-u,--url <url>               SOAP service URL, usually'),
         Regexp.escape('                             http[s]://host:port/service/soap or'),
         Regexp.escape('                             https://host:port/service/admin/soap.'),
         Regexp.escape('   --use-session             Use a SOAP session.'),
         Regexp.escape('-v,--verbose                 Print the request.'),
         Regexp.escape('-vv,--very-verbose           Print URLs and all requests and responses with'),
         Regexp.escape('                             envelopes.'),
         Regexp.escape('-z,--zadmin                  Authenticate with zimbra admin name/password from'),
         Regexp.escape('                             localconfig.'),
         Regexp.escape('Element paths roughly follow XPath syntax.  The path of each subsequent element'),
         Regexp.escape('is relative to the previous one.  To navigate up the element tree, use "../" in'),
         Regexp.escape('the path.  To specify attributes on the current element, use one or more'),
         Regexp.escape('@attr=val arguments.  To specify element text, use "path/to/element=text".'),
         Regexp.escape('Example: zmsoap -z GetAccountInfoRequest/account=user1 @by=name'),
        ]
#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmsoap"

#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [

  RunCommand.new('/bin/echo','root','test123', '>','/tmp/passfile'),

  ['h', '-help'].map do |x|
    v(ZMSoap.new('-' + x)) do |mcaller, data|
      mcaller.pass = data[0] == 0 &&
                     (lines = data[1].split(/\n/).select {|w| w !~ /^\s*$/}).size == usage.size &&
                     lines.select {|w| w !~ /#{usage.join('|')}/}.empty?
    end
  end,
  
  (('a'..'z').to_a + ('A'..'Z').to_a - %w[a A f h m n p P t u v z]).map do |x|
    v(ZMSoap.new('-' + x)) do |mcaller, data|
      mcaller.pass = data[0] != 0 &&
                     (lines = (data[1].split(/\n/) + data[2].split(/\n/)).select {|w| w !~ /^\s*$/}).size == usage.size + 1 &&
                     lines.select {|w| w !~ /#{usage.join('|')}|#{Regexp.escape('Unrecognized option: -' + x)}/}.empty?
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {'zmsoap unknown option' => {"IS"=>(data[1] + data[2]).select {|w| w !~ /#{usage.join('|')}/}, "SB"=>'Unrecognized option: -' + x}}
      end
    end
  end,

  v(ZMSoap.new('-z', '-m', 'admin@`zmhostname`', 'SearchRequest/query=in:inbox')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('SearchResponse')
  end,
  
  v(ZMSoap.new('-m', 'admin@`zmhostname`', '-p', Model::DEFAULTPASSWORD, 'SearchRequest/query=in:inbox')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('SearchResponse')
  end,

  v(ZMSoap.new('-a','admin@`zmhostname`','-p', 'test123', '-m', 'admin@`zmhostname`', 'SearchRequest/query=in:inbox')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('SearchResponse')
  end,

  v(ZMSoap.new('-a','admin@`zmhostname`','-P', '/tmp/passfile', '-m', 'admin@`zmhostname`', 'SearchRequest/query=in:inbox')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('SearchResponse')
  end,

  v(ZMSoap.new('-a','admin@`zmhostname`','-t', 'account', '-P', '/tmp/passfile', '-m', 'admin@`zmhostname`', 'SearchRequest/query=in:inbox')) do |mcaller, data|
    mcaller.pass = data[0] == 1 && data[1].include?('unknown document: SearchRequest')
  end,

  v(ZMSoap.new('-a','admin@`zmhostname`','-v', '-P', '/tmp/passfile', '-m', 'admin@`zmhostname`', 'SearchRequest/query=in:inbox')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('SearchRequest xmlns="urn:zimbraMail"')
  end,

  v(ZMSoap.new('-a','admin@`zmhostname`','-u','https://wronghost:7071/service/admin/soap', '-P', '/tmp/passfile', '-m', 'admin@`zmhostname`', 'SearchRequest/query=in:inbox')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('java.net.UnknownHostException: wronghost')
  end,

  v(ZMSoap.new('-a','admin@`zmhostname`','-n', '-m', 'admin@`zmhostname`', 'SearchRequest/query=in:inbox')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('</SearchRequest>')
  end,

  v(ZMSoapXml.new('-v', '-z', '-m', 'admin@`zmhostname`', '-t', 'mobile', 'GetDeviceStatusRequest')) do |mcaller, data|
    isNetwork = ZMControl.new('-v').run[1] =~ /NETWORK/
    mcaller.pass = isNetwork && data[0] == 0 && data[1].elements.size == 1 && !data[1].elements['GetDeviceStatusResponse'].nil? ||
                   !isNetwork && data[0] != 0
  end,
    
  RunCommand.new('/bin/echo', 'root', "\"{\\\"SearchRequest\\\":{\\\"_jsns\\\":\\\"urn:zimbraMail\\\", \\\"query\\\":\\\"in:inbox\\\"}}\"", '>','/tmp/jsonfile'),
    
  v(ZMSoap.new('-z', '-m', 'admin@`zmhostname`', '--json', '-f', '/tmp/jsonfile')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !(response = JSON.parse(data[1]) rescue nil).nil? &&
                   response.keys.sort & (keys = ["sortBy", "offset", "c", "more", "_jsns"].sort) == keys &&
                   response['_jsns'] == 'urn:zimbraMail'
  end,
    
  RunCommand.new('/bin/echo', 'root', "\"{\\\"GetDeviceStatusRequest\\\":{\\\"_jsns\\\":\\\"urn:zimbraSync\\\"}}\"", '>','/tmp/jsonfile'),

  v(ZMSoap.new('-z', '-m', 'admin@`zmhostname`', '-t', 'mobile', '--json', '-f', '/tmp/jsonfile')) do |mcaller, data|
    isNetwork = ZMControl.new('-v').run[1] =~ /NETWORK/
    mcaller.pass = isNetwork && data[0] == 0 && !(response = JSON.parse(data[1]) rescue nil).nil? &&
                   response.keys.sort & (keys = ["_jsns"].sort) == keys &&
                   response['_jsns'] == 'urn:zimbraSync'  ||
                   !isNetwork && data[0] != 0
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