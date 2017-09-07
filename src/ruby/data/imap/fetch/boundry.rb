#!/usr/bin/ruby -w
#
# = data/imap/fetch/boundry.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# IMAP FETCH boundry test cases
#
if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"
require "action/block"

require "action/zmprov"
require "action/proxy"
require "action/sendmail"
require "action/verify"
require "net/imap"; require "action/imap" #Patch Net::IMAP library

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP Fetch Boundry test"

name = 'ifetch'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
name = "admin" if ($0 == __FILE__)
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

m = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)

include Action

message = <<EOF
Received: from localhost (localhost.localdomain [127.0.0.1])
	by dogfood.zimbra.com (Postfix) with ESMTP id 5B2BE36F826;
	Tue,  2 Aug 2005 15:06:06 -0700 (PDT)
Received: from dogfood.zimbra.com ([127.0.0.1])
 by localhost (dogfood.zimbra.com [127.0.0.1]) (amavisd-new, port 10024)
 with ESMTP id 16246-01; Tue,  2 Aug 2005 15:06:06 -0700 (PDT)
Received: from zimbra.com (exch1.zimbra.com [10.10.130.37])
	by dogfood.zimbra.com (Postfix) with ESMTP id BDE4336F825;
	Tue,  2 Aug 2005 15:06:05 -0700 (PDT)
Received: from lab-loadgen02.zimbra.com ([4.78.240.39]) by zimbra.com with Microsoft SMTPSVC(6.0.3790.211);
	 Tue, 2 Aug 2005 15:11:20 -0700
Received: from dogfood.zimbra.com (dsl092-025-198.sfo1.dsl.speakeasy.net [66.92.25.198])
	by lab-loadgen02.zimbra.com (Postfix) with ESMTP id B1D80810038;
	Tue,  2 Aug 2005 15:11:01 -0700 (PDT)
Received: from localhost (localhost.localdomain [127.0.0.1])
	by dogfood.zimbra.com (Postfix) with ESMTP id D948E36F826;
	Tue,  2 Aug 2005 15:06:04 -0700 (PDT)
Received: from dogfood.zimbra.com ([127.0.0.1])
 by localhost (dogfood.zimbra.com [127.0.0.1]) (amavisd-new, port 10024)
 with ESMTP id 08844-05; Tue,  2 Aug 2005 15:06:04 -0700 (PDT)
Received: from dogfood.zimbra.com (localhost.localdomain [127.0.0.1])
	by dogfood.zimbra.com (Postfix) with ESMTP id 27A5436F825;
	Tue,  2 Aug 2005 15:06:04 -0700 (PDT)
MIME-Version: 1.0
Date: Tue, 2 Aug 2005 15:06:04 -0700 (PDT)
From: Kevin Kluge <kluge@zimbra.com>
To: "'all@zimbra.com'" <all@zimbra.com>,
	'Ben Kwok' <ben@zimbra.com>,
	"'nancy@zimbra.com'" <nancy@zimbra.com>
Subject: Phase out of Exchange -- Please Read
Thread-Topic: Phase out of Exchange -- Please Read
Thread-Index: AcWXrxrtQ48Wp3JNSJ+qPJeCIBRcDg==
X-Priority: 3
Content-Type: text/plain; charset=us-ascii;
Content-Transfer-Encoding: Quoted-printable
Message-ID: <533891.1123020364143.JavaMail.liquid@dogfood.zimbra.com>
X-Virus-Scanned: amavisd-new at zimbra.com
X-OriginalArrivalTime: 02 Aug 2005 22:11:20.0857 (UTC) FILETIME=[1CD2B890:01C597AF]
X-Virus-Scanned: amavisd-new at zimbra.com
X-Spam-Status: No, hits=-5.146 tagged_above=-10 required=6.6
 tests=[ALL_TRUSTED=-3.3, AWL=-0.344, BAYES_00=-2.599, PRIORITY_NO_NAME=1.097]
X-Spam-Level: 

Since we're building our own groupware system we don't want to run Exchange=
 as any part of our mail system.  We've put together  a plan to phase Excha=
nge out from the company's mail and calendar.  THERE IS ONE THING YOU NEED =
TO DO BY THIS THURSDAY 5 PM IN THAT PLAN. =20

The plan is to kill exchange-mail first on Thursday evening.  And then kill=
 exchange (taking out calendar) completely in a second phase.

For phase 1 (mail), dogfood does not have the notion of public folders.  If=
 there is anything in the public folders on Exchange that you want then you=
 need to copy it by hand to whereever you want to save it.  We've created \=
\kenny\public\public_folders as a starting point, but you can put it wheree=
ver.  You need to do this by Thursday 5 PM.

We've also put a PST file into that public_folders directory with the conte=
nts of the public folders.  If you'd rather, you can copy that .pst to your=
 local machine and open it with Outlook.  Just don't open the one in public=
_folders (without copying it to your machine first).  This .pst will be ava=
ilable indefinitely, if you miss the Thursday 5 PM deadline.

Results of phase 1 will be:
- Exchange no longer gets new mail
- Accept/Decline on calendar invites (done from Outlook) may not work
- Blackberries must be switched to IMAP to access mail
- public folders disappear
- all the distribution lists and aliases will be migrated


Phase 2 will be to have everyone move to the dogfood calendar, which will a=
llow us to shut off Exchange.  We're waiting for some more stability in the=
 calendar to do this.  This phase will hopefully happen late next week.  At=
 that time we'll ask everyone to move their appointments to dogfood by hand=
 (no import).  Results of phase 2 will be:
- Blackberry access to calendar ends
- All scheduling should be done with our app (not Outlook/OWA)

Let me know if you have any questions.

-kevin
EOF
 
#
# Setup
#
current.setup = [
   CreateAccount.new(testAccount.name,testAccount.password) 
]

#
# Execution
#
current.action = [  
  p(m.method('login'),testAccount.name,testAccount.password),
  p(m.method('create'),"INBOX/FETCHNEGATIVE"),
  cb("Create 7 messages using append") {       
    1.upto(7) { |i|
      m.append("INBOX/FETCHNEGATIVE",message.gsub(/REPLACEME/,i.to_s),[:Seen], Time.now) 
    }
    "Done"
  }, 
  p(m.method('select'),"INBOX/FETCHNEGATIVE"),
  #something that doesn't exist
  p(m.method('fetch'), 12345678, 'FLAGS'), 
  FetchVerify.new(m, 12345678,  ['FLAGS', 'FLAGS'], 'garbage', &IMAP::badResponseError('sequence number')),
  #bigger sequence set 
  p(m.method('fetch'), (1..-1), 'FLAGS'), 
  FetchVerify.new(m, (1..-1),  ['FLAGS', 'FLAGS'], :Seen),

  # some negative test casees
  #p(m.method('fetch'), 1..100, ['FLAGS', 'FLAGS']),
  FetchVerify.new(m, 1..100,  ['FLAGS', 'FLAGS'], 'garbage', &IMAP::badResponseError('sequence number')),
  v(p(m.method('send_command'), 'FETCH a (FLAGS)'), &IMAP::FetchParseError), 
  v(p(m.method('send_command'), 'FETCH 1 (FLAGS)(FLAGS)'), &IMAP::FetchParseError), 
  p(m.method('select'),"INBOX/FETCHNEGATIVE"),
  p(m.method('delete'),"INBOX/FETCHNEGATIVE"),  
]

#
# Tear Down
#
current.teardown = [     
  p(m.method('logout')),
  p(m.method('disconnect')),  
  DeleteAccount.new(testAccount.name)
]

if($0 == __FILE__)
  require 'engine/simple'
  
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run    
end
