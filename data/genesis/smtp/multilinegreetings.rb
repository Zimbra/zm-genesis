#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2011 VMWare, Inc.
#
# Check for zimbra SMTP client connection to a
# MTA configured with multi-line greetings

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 

mypath = 'data'
if($0 =~ /data\/genesis/)
  mypath += '/genesis'
end

require 'json'
require "model"
require 'model/user'
require 'model/json/request'
require 'model/json/loginrequest'
require 'model/json/sendmsgrequest'
require 'model/json/getmsgrequest'
require 'model/json/getaccountinforequest'
require "action/block"
require "action/zmprov"
require "action/verify"
require 'action/json/command'
require 'action/json/login'
require "#{mypath}/install/utils"
require "#{mypath}/install/configparser"
require 'net/http'
require 'net/https'


#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Multi-line greetings test"

include Action
include Action::Json
include Model
include Model::Json

defaultDomain = Model::TARGETHOST
accts=[]
messageid = ''
mConfig = ConfigParser.new()
mConfig.run
timeNow = Time.now.to_i.to_s


#
# Setup
#
current.setup = [
  
]
   
#
# Execution
#
current.action = [
  v(ZMProv.new('gcf', 'zimbraDefaultDomainName')) do |mcaller, data|
    if(data[1] =~ /Data\s+:/)
      data[1] = data[1][/Data\s+:\s+([^\s}].*?)$\s*\}/m, 1]
    end
    data[0] = 1 if data[1] == nil
    if data[0] == 0
      defaultDomain = data[1][/\s*zimbraDefaultDomainName:\s+(.*)$/, 1]
    end
    mcaller.pass = data[0] == 0
  end,

  v(cb("Accounts setup") do
    data = []
    admin = Model::User.new("admin@#{Utils::zimbraDefaultDomain}", Model::DEFAULTPASSWORD)
    alr = AdminLoginRequest.new(admin)
    alogin = AdminLogin.new(alr, Model::TARGETHOST, 7071, 'https').run
    (0..1).map do |x|
      testAccount = User.new("testMultiLineGreetings#{timeNow}#{x}@#{Utils::zimbraDefaultDomain}", Model::DEFAULTPASSWORD)
      data = CreateAccount.new(testAccount.name, testAccount.password).run
      if (data[0] == 0) or (data[1] =~/ERROR: account.ACCOUNT_EXISTS/)
        data[0] = 0
        mObject = Action::Json::Command.new(GetAccountInfoRequest.new(admin, testAccount), Model::TARGETHOST, 7071,
                                            'https')
        mResult = mObject.run
        publicUrl = mObject.result['publicMailURL'].first['_content']
        accts << [testAccount, publicUrl]
      else
        break
      end
    end
    data
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'Account setup' => {"IS" => data[2].strip(), "SB" => "Account created"}}
    end
  end,
  
  ZMProv.new('ms', Model::TARGETHOST.to_s, 'zimbraSmtpHostname', 'zqa-409.eng.vmware.com'),
  
  v(cb("Send message", 180) do
    myProtocol, myHost, myDomain, myPort = accts[0][1].match(/(https?):\/\/([^\.]+)\.([^:]+):(\d+).*/)[1..4]
    targetHost = Host.new(myHost, myDomain)
    login = Login.new(LoginRequest.new(accts[0][0]), targetHost, myPort, myProtocol).run
    mObject = Action::Json::Command.new(SendMsgRequest.new(accts[0][0], accts[1][0].name, "Notification from #{accts[0][0].name}",
                                        "multi-line greetings from MTA test"),
                                        targetHost, myPort, myProtocol)
    mResult = mObject.run
    messageid = begin mObject.result['m'][0]['id'] rescue nil end
    [mResult[0], mResult[0] == 0 ? mResult[1]['Body']: mResult[1]]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1]['SendMsgResponse'] != nil &&
                   data[1]['SendMsgResponse']['m'] != nil
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'multi-line greetings check' => {"IS" => data[1], "SB" => 'pass'}}
    end
  end,
  
]

#
# Tear Down
#
current.teardown = [
  ZMProv.new('ms', Model::TARGETHOST.to_s, 'zimbraSmtpHostname', Model::TARGETHOST.to_s),
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end 