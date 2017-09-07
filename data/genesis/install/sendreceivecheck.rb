#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2006 Zimbra
#
#

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
require "action/zmamavisd"
require 'action/zmmailbox'
require 'net/http'
require 'net/https'


#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Send/receive mail test"

include Action
include Action::Json
include Model
include Model::Json

defaultDomain = Model::TARGETHOST
accts=[]
messageid = ''
disableAntivirusRequired = false
mConfig = ConfigParser.new()
mConfig.run
eicarMessage = 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*'

def accountAttribute(account, attr)
  data = ZMProv.new('ga', account.name.downcase, attr).run
  if(data[1] =~ /Data\s+:/)
      data[1] = data[1][/Data\s+:\s+([^\s}].*?)$\s*\}/m, 1]
  end
  data[0] = 1 if data[1] == nil
  if data[0] == 0
    data[1] = data[1][/\s*#{attr}:\s+(.*)$/, 1]
  end
  data
end

nNow = Time.now.to_i.to_s


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
    #admin = User.new("admin@#{defaultDomain}", Model::DEFAULTPASSWORD)
    admin = Utils::getAdmins.first
    alr = AdminLoginRequest.new(admin)
    mStores = mConfig.getServersRunning('store').select {|w| 'yes' == XPath.first(mConfig.doc, "//host[@name='#{w}']//option[@name='SERVICEWEBAPP']").text rescue 'yes'}
    mServer = mStores.first
    mPort = '7071'
    if ZMProv.new('gcf', 'zimbraReverseProxyAdminEnabled').run[1] =~ /TRUE/
      mServer = mConfig.getServersRunning('proxy').first
      mPort = '9071'
    end
    alogin = AdminLogin.new(alr, mServer, mPort, 'https').run
    (0..1).map do |x|
      testAccount = User.new("testSendReceive#{x}@#{Utils::zimbraDefaultDomain}", Model::DEFAULTPASSWORD)
      data = CreateAccount.new(testAccount.name, testAccount.password, 'zimbraMailHost', mStores[x] || mStores.first).run
      if (data[0] == 0) or (data[1] =~/ERROR: account.ACCOUNT_EXISTS/)
        data[0] = 0
        mObject = Action::Json::Command.new(GetAccountInfoRequest.new(admin, testAccount), mServer, mPort, 'https')
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
  
  v(cb("Send message", 180) do
    myProtocol, myHost, myDomain, myPort = accts[0][1].match(/(https?):\/\/([^\.]+)\.([^:]+):(\d+).*/)[1..4]
    targetHost = Host.new(myHost, myDomain)
    login = Login.new(LoginRequest.new(accts[0][0]), targetHost, myPort, myProtocol).run
    mObject = Action::Json::Command.new(SendMsgRequest.new(accts[0][0], accts[1][0].name, "Notification#{nNow} from #{accts[0][0].name}", "amessage"),
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
      mcaller.badones = {'Send message' => {"IS" => data[1], "SB" => 'pass'}}
    end
  end,
  
  v(cb("Retrieve message", 600) do
    mResult = [0, nil]
    store = accountAttribute(accts[0][0], 'zimbraMailTransport')[1].split(":")[1]
    mta = ZMProv.new('gs', store, 'zimbraSmtpHostname').run[1].split(/\n/).last[/zimbraSmtpHostname:\s*(.*)/, 1]
    (1..60).each do |i|
      mResult = RunCommand.new('postqueue', 'zimbra', '-p', Model::Host.new(mta)).run
      break if mResult[0] == 0 && mResult[1] =~ /Mail queue is empty/
      mResult[0] = 1
      sleep 10
    end
    next(mResult) if mResult[0] != 0
    mResult = ZMMail.new('-m', accts[1][0].name, '-p', accts[1][0].password, 's', "\"in:inbox subject:Notification#{nNow}\"", Model::Host.new(store)).run
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1] =~ /Notification#{nNow}/
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true   
      end
      mcaller.badones = {'Get message' => {"IS" => "#{data[1]}, exit code = #{data[0]}", "SB" => 'success'}}
    end
  end,
  
  mConfig.getServersRunning('mta').map do |x|
    v(cb("Enable Zimbra antivirus",300) do
      exitCode = 0
      res = ''
      mObject = ZMLocal.new(h = Model::Host.new(x), 'zimbra_server_hostname')
      server = mObject.run
      next[0, 'Skipping - non cluster only'] if mConfig.isClustered(server)
      mResult = ZMProv.new('gs', server).run
      if(mResult[1] =~ /Data\s+:/)
        mResult[1] = mResult[1][/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
      end
      config = mResult[1].chomp
      eservices = config.split(/\n/).select {|w| w =~ /^zimbraServiceEnabled:\s+.*$/}.collect {|w| w[/zimbraServiceEnabled:\s+(.*)\s*$/, 1]}
      next([0, 'Skipping - antivirus already enabled']) if eservices.include?('antivirus')
      iservices = config.split(/\n/).select {|w| w =~ /zimbraServiceInstalled:\s+.*$/}.collect {|w| w[/zimbraServiceInstalled:\s+(.*)\s*$/, 1]}
      next([1, 'antivirus is not installed']) if !iservices.include?('antivirus')
      disableAntivirusRequired = true
      cmd = ['+zimbraServiceEnabled', 'antivirus']
      mResult = ZMProv.new('ms', server, *cmd).run
      if mResult[0] != 0
        exitCode += 1 
        if(mResult[1] =~ /Data\s+:/)
          mResult[1] = mResult[1][/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
        end
        res += mResult[1] + '\n'
      end
      mResult = ZMMtactl.new('reload', h).run
      if mResult[0] != 0
        exitCode += 1 
        if(mResult[1] =~ /Data\s+:/)
          mResult[1] = mResult[1][/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
        end
        res += mResult[1] + '\n'
      end
      mResult = ZMAntivirusctl.new('restart', h).run
      if mResult[0] != 0
        exitCode += 1 
        if(mResult[1] =~ /Data\s+:/)
          mResult[1] = mResult[1][/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
        end
        res += mResult[1] + '\n'
      end
      [exitCode, res]
    end) do |mcaller, data|
      mcaller.pass = data[0] == 0
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {x + ' - Enable Zimbra antivirus' => {"IS" => data[1], "SB" => "Success"}}
      end
    end
  end,
  
  v(cb("Send eicar message", 180) do
    myProtocol, myHost, myDomain, myPort = accts[0][1].match(/(https?):\/\/([^\.]+)\.([^:]+):(\d+).*/)[1..4]
    targetHost = Host.new(myHost, myDomain)
    #empty quarantine inbox
    mResult = ZMProv.new('gcf', 'zimbraAmavisQuarantineAccount').run
    if(mResult[1] =~ /Data\s+:/)
      mResult[1] = mResult[1][/Data\s+:\s+([^\s}].*?)$\s*\}/m, 1]
    end
    qAccount = mResult[1][/zimbraAmavisQuarantineAccount:\s+(\S+)/, 1]
    mResult = RunCommand.new('zmmailbox', Command::ZIMBRAUSER,
                             '-z', '-m', qAccount, 
                             'ef', 'inbox').run
    login = Login.new(LoginRequest.new(accts[0][0]), targetHost, myPort, myProtocol).run
    mObject = Action::Json::Command.new(SendMsgRequest.new(accts[0][0], accts[1][0].name, "TestAV from #{accts[0][0].name}", eicarMessage),
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
      mcaller.badones = {'Send message' => {"IS" => data[1], "SB" => 'pass'}}
    end
  end,
  
  v(cb("quarantine mailbox test", 600) do
    mResult = [0, nil]
    store = accountAttribute(accts[0][0], 'zimbraMailTransport')[1].split(":")[1]
    mta = ZMProv.new('gs', store, 'zimbraSmtpHostname').run[1].split(/\n/).last[/zimbraSmtpHostname:\s*(.*)/, 1]
    (1..60).each do |i|
      mResult = RunCommand.new('postqueue', 'zimbra', '-p', Model::Host.new(mta)).run
      #puts mResult
      if(mResult[1] =~ /Data\s+:/)
        mResult[1] = mResult[1][/Data\s+:\s+([^\s}].*?)$\s*\}/m, 1]
      end
      break if mResult[0] == 0 && mResult[1] =~ /Mail queue is empty/
      mResult[0] = 1
      sleep 10
    end
    next(mResult) if mResult[0] != 0
    mResult = ZMProv.new('gcf', 'zimbraAmavisQuarantineAccount').run
    if(mResult[1] =~ /Data\s+:/)
      mResult[1] = mResult[1][/Data\s+:\s+([^\s}].*?)$\s*\}/m, 1]
    end
    qAccount = mResult[1][/zimbraAmavisQuarantineAccount:\s+(\S+)/, 1]
    mResult = ZMMail.new('-z', '-m', qAccount, 
                             's', '-t', 'message', 'in:inbox', Model::Host.new(store)).run
    if(mResult[1] =~ /Data\s+:/)
      mResult[1] = mResult[1][/Data\s+:\s+([^\s}].*?)$\s*\}/m, 1]
    end
    mResult
  end) do |mcaller, data|
    mcaller.pass = begin 
                     data[0] == 0 && data[1] != nil &&
                     !data[1].split("\n").select {|w| w =~ /mess\s+.*\s+TestAV from\s+#{accts[0][0].name[/([^@]+@)/, 1]}.*/}.empty?
                   rescue
                     false
                   end
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true   
      end
      mcaller.badones = {'quarantine mailbox check' => {"IS" => "#{data[1]}, exit code = #{data[0]}", "SB" => 'eicar quarantined in inbox'}}
    end
  end,
  
  mConfig.getServersRunning('mta').map do |x|
    v(cb("Disable Zimbra antivirus",300) do
      next([0, 'Skipping - disable antivirus not needed']) if !disableAntivirusRequired
      exitCode = 0
      res = ''
      mObject = ZMLocal.new(h = Model::Host.new(x), 'zimbra_server_hostname')
      server = mObject.run
      next([0, 'Skipping - non cluster only']) if mConfig.isClustered(server)
      mResult = ZMProv.new('gs', server).run
      if(mResult[1] =~ /Data\s+:/)
        mResult[1] = mResult[1][/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
      end
      config = mResult[1].chomp
      eservices = config.split(/\n/).select {|w| w =~ /^zimbraServiceEnabled:\s+.*$/}.collect {|w| w[/zimbraServiceEnabled:\s+(.*)\s*$/, 1]}
      next([0, 'Skipping - antivirus already disabled']) if !eservices.include?('antivirus')
      iservices = config.split(/\n/).select {|w| w =~ /zimbraServiceInstalled:\s+.*$/}.collect {|w| w[/zimbraServiceInstalled:\s+(.*)\s*$/, 1]}
      next([0, 'antivirus is not installed']) if !iservices.include?('antivirus')
      cmd = ['-zimbraServiceEnabled', 'antivirus']
      mResult = ZMProv.new('ms', server, *cmd).run
      if mResult[0] != 0
        exitCode += 1 
        if(mResult[1] =~ /Data\s+:/)
          mResult[1] = mResult[1][/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
        end
        res += mResult[1] + '\n'
      end
      mResult = ZMMtactl.new('reload', h).run
      if mResult[0] != 0
        exitCode += 1 
        if(mResult[1] =~ /Data\s+:/)
          mResult[1] = mResult[1][/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
        end
        res += mResult[1] + '\n'
      end
      mResult = ZMAntivirusctl.new('restart', h).run
      if mResult[0] != 0
        exitCode += 1 
        if(mResult[1] =~ /Data\s+:/)
          mResult[1] = mResult[1][/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
        end
        res += mResult[1] + '\n'
      end
      [exitCode, res]
    end) do |mcaller, data|
      mcaller.pass = data[0] == 0
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {x + ' - Disable Zimbra antivirus' => {"IS" => data[1], "SB" => "Success"}}
      end
    end
  end,
  
=begin
TODO: check the av notification in receiver's inbox
check virus-q inbox has n items
send a new message
check virus-q inbox == n + 1 items
bonus: check the content as below
zmmailbox -z -m virus-quarantine.orxggirmg2@zqa-065.eng.vmware.com s -t message in:inbox
num: 1, more: false

     Id  Type   From                  Subject                                             Date
   ----  ----   --------------------  --------------------------------------------------  --------------
1.  257  mess   testsendreceive0      fff                                                 10/19/10 18:47

zimbra@zqa-065:~$ zmmailbox -z -m virus-quarantine.orxggirmg2@zqa-065.eng.vmware.com gm 257
Id: 257
Conversation-Id: -257
Folder: /Inbox
Subject: fff
From: <testsendreceive0@zqa-065.eng.vmware.com>
To: <testsendreceive1@zqa-065.eng.vmware.com>
Date: Tue, 19 Oct 2010 18:47:50 -0700 (PDT)
Size: 1.97 KB

From: user@example.com
To: user@example.com
Subject: test av
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="=-=-="

--=-=-=


testing av


--=-=-=
Content-Disposition: attachment; filename=eicar.com

X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*

--=-=-=--


zimbra@zqa-065:~$ zmmailbox -z -m virus-quarantine.orxggirmg2@zqa-065.eng.vmware.com s -t message in:inbox
num: 1, more: false

     Id  Type   From                  Subject                                             Date
   ----  ----   --------------------  --------------------------------------------------  --------------
1.  257  mess   testsendreceive0      fff                                                 10/19/10 18:47

zimbra@zqa-065:~$ zmmailbox -z -m virus-quarantine.orxggirmg2@zqa-065.eng.vmware.com gm 257Id: 257
Conversation-Id: -257
Folder: /Inbox
Subject: fff
From: <testsendreceive0@zqa-065.eng.vmware.com>
To: <testsendreceive1@zqa-065.eng.vmware.com>
Date: Tue, 19 Oct 2010 18:47:50 -0700 (PDT)
Size: 1.97 KB

From: user@example.com
To: user@example.com
Subject: test av
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="=-=-="

--=-=-=


testing av


--=-=-=
Content-Disposition: attachment; filename=eicar.com

X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*

--=-=-=--
=end
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