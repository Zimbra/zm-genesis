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
current.description = "IMAP Fetch Binary test"

name = 'ifetch'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
name = "admin" if ($0 == __FILE__)
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

m = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)

include Action

message = <<EOF
Received: from localhost (localhost.localdomain [127.0.0.1])
  by dogfood.zimbra.com (Postfix) with ESMTP id 61FFF36E4F2
  for <bhwang@dogfood.zimbra.com>; Tue,  2 Aug 2005 00:57:55 -0700 (PDT)
Received: from dogfood.zimbra.com ([127.0.0.1])
 by localhost (dogfood.zimbra.com [127.0.0.1]) (amavisd-new, port 10024)
 with ESMTP id 24652-01 for <bhwang@dogfood.zimbra.com>;
 Tue,  2 Aug 2005 00:57:53 -0700 (PDT)
Received: from zimbra.com (exch1.zimbra.com [10.10.130.37])
  by dogfood.zimbra.com (Postfix) with ESMTP id 4CD8436E4D4
  for <bhwang@dogfood.zimbra.com>; Tue,  2 Aug 2005 00:57:53 -0700 (PDT)
Received: from lab-loadgen02.zimbra.com ([4.78.240.39]) by zimbra.com with Microsoft SMTPSVC(6.0.3790.211);
   Tue, 2 Aug 2005 01:03:06 -0700
Received: from nez-perce.test.com (nez-perce.test.com [192.93.2.78])
  by lab-loadgen02.zimbra.com (Postfix) with ESMTP id CDEF6810492
  for <bhwang@zimbra.com>; Tue,  2 Aug 2005 01:02:47 -0700 (PDT)
Received: from yquem.test.com (yquem.test.com [128.93.8.37])
  by nez-perce.test.com (8.13.0/8.13.0) with ESMTP id j7281JHj032034;
  Tue, 2 Aug 2005 10:01:19 +0200
Received: from yquem.test.com (localhost [127.0.0.1])
  by yquem.test.com (Postfix) with ESMTP id 76C65BBA5;
  Tue,  2 Aug 2005 10:01:17 +0200 (CEST)
X-Original-To: caml-list@yquem.test.com
Delivered-To: caml-list@yquem.test.com
Received: from concorde.test.com (concorde.test.com [192.93.2.39])
  by yquem.test.com (Postfix) with ESMTP id A6F95BB88
  for <caml-list@yquem.test.com>; Tue,  2 Aug 2005 10:01:15 +0200 (CEST)
Received: from pauillac.test.com (pauillac.test.com [128.93.11.35])
  by concorde.test.com (8.13.0/8.13.0) with ESMTP id j7281F1a004573
  for <caml-list@yquem.test.com>; Tue, 2 Aug 2005 10:01:15 +0200
Received: from nez-perce.test.com (nez-perce.test.com [192.93.2.78]) by
  pauillac.test.com (8.7.6/8.7.3) with ESMTP id KAA12904 for
  <caml-list@pauillac.test.com>;
  Tue, 2 Aug 2005 10:01:14 +0200 (MET DST)
Received: from mx1.testme.com (mx1.testme.com [129.104.30.34])
  by nez-perce.test.com (8.13.0/8.13.0) with ESMTP id j7281EOX032009
  for <caml-list@test.com>; Tue, 2 Aug 2005 10:01:14 +0200
Received: from alan-schm1p.test.com (alan-schm1p.test.com [128.93.20.79])
  (using TLSv1 with cipher DHE-RSA-AES256-SHA (256/256 bits))
  (No client certificate requested)
  by ssl.testme.com (Postfix) with ESMTP id 8F4323317A
  for <caml-list@test.com>; Tue,  2 Aug 2005 10:01:07 +0200 (CEST)
Received: from [127.0.0.1] (localhost [127.0.0.1])
  by alan-schm1p.test.com (Postfix) with ESMTP id B43CA188C32
  for <caml-list@test.com>; Tue,  2 Aug 2005 09:59:24 +0200 (CEST)
Mime-Version: 1.0 (Apple Message framework v733)
In-Reply-To: <F0577640-623F-4147-9745-300F4303D3E6@testme.com>
References: <F0577640-623F-4147-9745-300F4303D3E6@testme.com>
Message-Id: <429BB1F8-71FA-4AE1-95D6-F6C589DDEC58@testme.com>
From: Alan Schmitt <alan.schmitt@testme.com>
Subject: Re: [Caml-list] Named pipe problem: is this a bug?
Date: Tue, 2 Aug 2005 09:59:20 +0200
To: caml-list@test.com
X-Pgp-Agent: GPGMail 1.1 (Tiger)
X-Mailer: Apple Mail (2.733)
X-AV-Checked: ClamAV using ClamSMTP at djali.testme.com (Tue Aug 2
  10:01:14 2005 +0200 (CEST))
X-DCC--Metrics: djali 32702; Body=1 Fuz1=1 Fuz2=1
X-Org-Mail: alan.schmitt.1995@testme.com
X-Miltered: at nez-perce with ID 42EF284F.001 by Joe's j-chkmail (http://j-chkmail.ensmp.fr)!
X-Miltered: at concorde with ID 42EF284B.001 by Joe's j-chkmail
  (http://j-chkmail.ensmp.fr)!
X-Miltered: at nez-perce with ID 42EF284A.000 by Joe's j-chkmail
  (http://j-chkmail.ensmp.fr)!
X-Spam: no; 0.00;
  schmitt:01 schmitt:01 caml-list:01 bug:01 alan:01 alan:01 hacker:02
  fifo:04 problem:05 something:12 issue:12 but:12 pipe:13 does:14
  figured:16 
X-Attachments: type="application/pgp-signature" name="PGP.sig" name="PGP.sig" 
X-BeenThere: caml-list@yquem.test.com
X-Mailman-Version: 2.1.5
Precedence: list
List-Id: Caml users' mailing list <caml-list.yquem.test.com>
List-Unsubscribe: <http://yquem.test.com/cgi-bin/mailman/listinfo/caml-list>, 
  <mailto:caml-list-request@yquem.test.com?subject=unsubscribe>
List-Post: <mailto:caml-list@yquem.test.com>
List-Help: <mailto:caml-list-request@yquem.test.com?subject=help>
List-Subscribe: <http://yquem.test.com/cgi-bin/mailman/listinfo/caml-list>,
  <mailto:caml-list-request@yquem.test.com?subject=subscribe>
Mime-version: 1.0
Sender: caml-list-bounces@yquem.test.com
Errors-To: caml-list-bounces@yquem.test.com
X-j-chkmail-Score: MSGID : 42EF284F.001 on nez-perce : j-chkmail score : X : 0/20 1
X-OriginalArrivalTime: 02 Aug 2005 08:03:06.0932 (UTC) FILETIME=[9DAE0F40:01C59738]
X-Virus-Scanned: amavisd-new at zimbra.com
X-Spam-Status: No, hits=-2.599 tagged_above=-10 required=6.6 autolearn=ham
 tests=[BAYES_00=-2.599]
X-Spam-Level: 
MIME-version: 1.0
Content-type: multipart/mixed; boundary="frontier"

This is a multi-part message in MIME format.
--frontier
Content-type: text/plain

This is the body of the message.
--frontier
Content-type: application/octet-stream
Content-transfer-encoding: base64

PGh0bWw+CiAgPGhlYWQ+CiAgPC9oZWFkPgogIDxib2R5PgogICAgPHA+VGhpcyBpcyB0aGUg
Ym9keSBvZiB0aGUgbWVzc2FnZS48L3A+CiAgPC9ib2R5Pgo8L2h0bWw+Cg==
--frontier-- 

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
  p(m.method('create'),"INBOX/FETCHMIME"),
  cb("Create a message using append") {       
    1.upto(1) { |i|
      m.append("INBOX/FETCHMIME",message.gsub(/REPLACEME/,i.to_s),[:Seen], Time.now) 
    }
    "Done"
  },   
  {'BINARY[2]<90.100>' => '/html>', 
    }.map do |x|
      IMAP.genFetchAction([Model::TARGETHOST, Model::IMAPSSL, true], testAccount, 'INBOX/FETCHMIME', x) 
  end,  
  p(m.method('delete'),"INBOX/FETCHMIME"),  
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
