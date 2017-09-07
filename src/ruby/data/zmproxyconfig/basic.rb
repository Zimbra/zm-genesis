#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2012 Vmware Zimbra
#
# Basic test zmproxyconfig
#


if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "action/zmproxyconfig"

include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmproxyconfig"

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
  v(ZMProxyconfig.new('-h')) do |mcaller,data|
	  mcaller.pass = data[0] != 0 && 
                   data[1].include?("Usage: /opt/zimbra/libexec/zmproxyconfig [-h] [-o] [-m] [-w] [-d [-r] [-s] [-a w1:w2:w3:w4] [-c [-n n1:n2]] [-i p1:p2:p3:p4] [-p p1:p2:p3:p4] [-x mailmode]] [-e [-a w1:w2:w3:w4] [[-c|-C] [-n n1:n2]] [-i p1:p2:p3:p4] [-p p1:p2:p3:p4] [-u|-U] [-x mailmode]] [-f] -H hostname") &&
                   data[1].include?("-h: display this help message") &&	
                   data[1].include?("-H: Hostname of server on which enable/disable proxy functionality") &&	
                   data[1].include?("-a: Colon separated list of Web ports to use. Format: HTTP-STORE:HTTP-PROXY:HTTPS-STORE:HTTPS-PROXY (Ex: 8080:80:8443:443)") &&	
                   data[1].include?("-d: disable proxy") &&	
                   data[1].include?("-e: enable proxy") &&	
                   data[1].include?("-f: Full reset on memcached port and search queries and POP/IMAP throttling") &&	
                   data[1].include?("-i: Colon separated list of IMAP ports to use. Format: IMAP-STORE:IMAP-PROXY:IMAPS-STORE:IMAPS-PROXY (Ex: 7143:143:7993:993)") &&	
                   data[1].include?("-m: Toggle mail proxy portions") &&	
                   data[1].include?("-o: Override enabled checks") &&	
                   data[1].include?("-p: Colon separated list of POP ports to use. Format: POP-STORE:POP-PROXY:POPS-STORE:POPS-PROXY (Ex: 7110:110:7995:995)") &&	
                   data[1].include?("-r: Run against a remote host.  Note that this requires the server to be") &&	
                   data[1].include?("-s: Set cleartext to FALSE (secure mode) on disable") &&	
                   data[1].include?("-t: Disable reverse proxy lookup target for store server.  Only valid wi") &&	
                   data[1].include?("-w: Toggle Web proxy portions") &&	
                   data[1].include?("-c: Disable Admin Console proxy portions") &&
                   data[1].include?("-C: Enable Admin Console proxy portions") &&
                   data[1].include?("-n: Colon separated list of Admin Console ports to use. Format: ADMIN-CONSOLE-STORE:ADMIN-CONSOLE-PROXY (Ex: 7071:9071)") &&	
                   data[1].include?("-x: the proxy mail mode when enable proxy, or the store mail mode when disable proxy (Both default: http)") &&	
                   data[1].include?("-u: disable SSL connection from proxy to mail store") &&	
                   data[1].include?("-U: enable SSL connection from proxy to mail store")
                                 
  end,
  
  # not known command
  v(ZMProxyconfig.new('stop')) do |mcaller,data|
    mcaller.pass = data[0] != 0 && data[1].include?("Usage:")
  end,
  
  # not known key
  v(ZMProxyconfig.new('-W', '2>&1')) do |mcaller,data|
    mcaller.pass = data[0] != 0 &&
                    data[1].include?("Unknown option:") &&
                    data[1].include?("Unable to set options")
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
