#!/usr/bin/ruby -w
#
# data/genesis/imap/extension/gssapi/setup.rb
#
# Copyright (c) 2010 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# IMAP GSSAPI setup
#
# Setup test.com domain with gssapi enabled
#
if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 


 
require "model"
require "action/zmcontrol"
require "action/zmprov"
require "action/imap"
require "action/block"
require "action/proxy"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP GSSAPI Setup"

include Action

 
#
# Setup
#
current.setup = [
                 
                ]

#
# Execution
#
current.action = [  
                  ZMProv.new('ms',  Model::TARGETHOST, 'zimbraImapSaslGssapiEnabled', 'TRUE'),
                  ZMProv.new('ms',  Model::TARGETHOST, 'zimbraReverseProxyImapSaslGssapiEnabled', 'TRUE'),
                  ZMProv.new('cd', 'testme.com', 'zimbraAuthMech', 'kerberos5', 'zimbraAuthKerberos5Realm',
                             'ZIMBRAQA.COM'),
                  if (Model::TARGETHOST.proxy)
                    [ ZMProv.new('mcf', '+zimbraReverseProxyAdminIPAddress', Model::TARGETHOST.ip),
                      ZMProv.new('ms',  Model::TARGETHOST, 'zimbraReverseProxyDefaultRealm', 'ZIMBRAQA.COM') ]
                  end,
                  ZMControl.new('stop'),
                  ZMControl.new('start'),
                  cb("Change other tests behavior") do
                    CapabilityVerify.addCapability("AUTH=GSSAPI")
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
