#!/usr/bin/ruby -w
#
# = action/append.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# IMAP append test cases
# 

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model" 
require "uri"

require "action/block" 
require "action/zmprov"
require "action/proxy"
require "action/sendmail"
require "action/verify" 
require "action/zmcontrol"
require "action/waitqueue"


#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Filter crash test"

include Action 

name = 'filter'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s

testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

 
 
#
# Setup
#
current.setup = [
  
]

filter =<<FEOF
require ["fileinto","reject", "tag", "flag"];
#F1

 if anyof (header :contains "from" ""foo@bar.com" ")

{

        fileinto "/Trash";

    stop;

}
 
#F2

 if anyof (header :contains "from" "foo@bar.com")

{

        fileinto "/Trash";

    stop;

}
 
#F3

 if anyof (header :contains "from" ""foo@bar.com" ")

{

        fileinto "/Trash";

    stop;

}
 
#F4

 if anyof )

{

        fileinto "/Trash";

    stop;

} 
FEOF
 
message = <<EOF.gsub(/\n/, "\r\n").gsub(/REPLACEME/, testAccount.name)
Message-ID: <45DF8D60.70202@boris-d600.test.com>
Date: Fri, 23 Feb 2007 16:57:04 -0800
From: user1 <user1@boris-d600.test.com>
User-Agent: Thunderbird 1.5.0.9 (Windows/20061207)
MIME-Version: 1.0
To:  user1@boris-d600.test.com
Subject: attachment 3
Content-Type: multipart/mixed;
 boundary="------------050508030005020207050501"

This is a multi-part message in MIME format.
--------------050508030005020207050501
Content-Type: text/plain; charset=ISO-8859-1; format=flowed
Content-Transfer-Encoding: 7bit



--------------050508030005020207050501
Content-Type: application/pdf;
 name="marketimer-200702.pdf"
Content-Transfer-Encoding: base64
Content-Disposition: inline;
 filename="marketimer-200702.pdf"
 
MDAwMDAgbg0KMDAwMDA3NjI1OSAwMDAwMCBuDQowMDAwMDc2Mjk0IDAwMDAwIG4NCjAwMDAw
NzYzMTggMDAwMDAgbg0KMDAwMDA3NjQxNiAwMDAwMCBuDQowMDAwMDc5OTc3IDAwMDAwIG4N
CnRyYWlsZXINCjw8L1NpemUgNDEvRW5jcnlwdCA0MiAwIFI+Pg0Kc3RhcnR4cmVmDQoxMTYN
CiUlRU9GDQo=
--------------050508030005020207050501--
EOF
#
# Execution
#
current.action = [  
  CreateAccount.new(testAccount.name,testAccount.password),
  ZMProv.new('ma', testAccount.name, "zimbraMailSieveScript", '"'+URI.escape(filter)+'"'),
  v(cb("Send an email") {
    SendMail.new(testAccount.name,message).run
    Kernel.sleep(20)
    response = Action::RunCommandOnMailbox.new('grep','root', '-i fatal /opt/zimbra/log/mailbox.log').run
    Kernel.sleep(20)
    response
  }) do |mcaller, data|
    mcaller.pass = !data[1].include?('FATAL')
  end,  
  Action::ZMControl.new('stop'),
  Action::ZMControl.new('start'), 
  ZMProv.new('ma', testAccount.name, "zimbraMailSieveScript", '""'),
]

#
# Tear Down
#
current.teardown = [      
 
  DeleteAccount.new(testAccount.name)
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end 
