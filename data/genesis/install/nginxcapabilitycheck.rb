#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2007 Zimbra
#
#  The script is pretty limited at this moment.  This will only check if nginx and mbs are installed on the same server

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model" 
require "action/block"
require "action/runcommand" 
require "action/verify"
require "net/pop"
require "net/imap"; require "action/imap" #Patch Net::IMAP library

include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Nginx IMAP capability check"


def getImapCapability(pHost)
  extraProxyFeatures = ["LOGINDISABLED"]
  extraRealFeatures = ["AUTH=PLAIN", "AUTH=X-ZIMBRA", "LOGIN-REFERRALS"]
  begin
  proxyCapability = Net::IMAP.new(pHost,143).capability
  proxySSLCapability = Net::IMAP.new(pHost,993, true).capability
  realCapability = Net::IMAP.new(pHost,7143).capability
  realSSLCapability = Net::IMAP.new(pHost,7993, true).capability
  { :extraproxy => proxyCapability - realCapability - extraProxyFeatures, 
    :extrareal => realCapability - proxyCapability - extraRealFeatures, 
    :extrasslproxy => proxySSLCapability - realSSLCapability - extraProxyFeatures,
    :extrasslreal => realSSLCapability - proxySSLCapability - extraRealFeatures}
  rescue Errno::ECONNREFUSED  #not set up for proxy, pass
    { :extraproxy => [], 
    :extrareal => [], 
    :extrasslproxy => [],
    :extrasslreal => []}
  end
end 

# Setup
#
current.setup = [ 
]

#
# Execution
# 
current.action = [  
  v(cb("get list of capabilities") {getImapCapability(Model::TARGETHOST)}  
  ) { |mcaller, data|
    mcaller.pass = data.all? {|x, y| y == [] } #if there is no difference, test passes
  },
  
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
