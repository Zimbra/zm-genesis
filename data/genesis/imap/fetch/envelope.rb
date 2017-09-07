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
# IMAP FETCH envelope test cases
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
current.description = "IMAP Fetch Mime test"

name = 'ifetch'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
name = "admin" if ($0 == __FILE__)
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

m = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)

include Action

message = <<EOF
Return-Path: <xmlbeans-user-return-48-smith=testme.com@xml.test.com>
Received: from leland8.Stanford.EDU (leland8.Stanford.EDU [171.67.16.82])
	by popserver1.Stanford.EDU (8.12.10/8.12.10) with ESMTP id h9AJr4LB009444
	for <smith@popserver1.testme.com>; Fri, 10 Oct 2003 12:53:04 -0700
	(PDT)
Received: from mail.test.com (daedalus.test.com [208.185.179.12]) by
	leland8.Stanford.EDU (8.12.10/8.12.10) with SMTP id h9AJquCa014182 for
	<smith@testme.com>; Fri, 10 Oct 2003 12:52:57 -0700 (PDT)
Received: (qmail 40887 invoked by uid 500); 10 Oct 2003 19:52:50 -0000
Mailing-List: contact xmlbeans-user-help@xml.test.com; run by ezmlm
Precedence: bulk
X-No-Archive: yes
List-Post: <mailto:xmlbeans-user@xml.test.com>
List-Help: <mailto:xmlbeans-user-help@xml.test.com>
List-Unsubscribe: <mailto:xmlbeans-user-unsubscribe@xml.test.com>
List-Subscribe: <mailto:xmlbeans-user-subscribe@xml.test.com>
Reply-To: xmlbeans-user@xml.test.com
Delivered-To: mailing list xmlbeans-user@xml.test.com
Received: (qmail 40873 invoked from network); 10 Oct 2003 19:52:50 -0000
X-MimeOLE: Produced By Microsoft Exchange V6.0.6375.0
content-class: urn:content-classes:message
MIME-Version: 1.0
Content-Type: text/plain; charset="iso-8859-1"
Content-Transfer-Encoding: quoted-printable
Subject: RE: noNamespace package alternatives
Date: Fri, 10 Oct 2003 12:52:52 -0700
Message-ID: <4B2B4C417991364996F035E1EE39E2E11E9DBD@uskiex01.amer.test.co>
X-MS-Has-Attach: 
X-MS-TNEF-Correlator: 
Thread-Topic: noNamespace package alternatives
Thread-Index: AcOPXpyOI+Mul6HaSsOuJNKGEY2xUQAB6a4gAABm8jA=
From: "Eric Vasilik" <ericvas@bea.com>
To: <xmlbeans-user@xml.test.com>
CC: Mickey Mouse <mouse@example.com>, friends: Jane Doe <doe@example.com>,
	rmccorrigan@example.com;
X-OriginalArrivalTime: 10 Oct 2003 19:52:53.0291 (UTC)
	FILETIME=[17AA3FB0:01C38F68]
X-Spam-Rating: daedalus.test.com 1.6.2 0/1000/N
X-Evolution-Source: imap://smith@smith.pobox.testme.com/
X-Evolution: 00000071-0010

The -repackage option exists for the purposes of building the XmlBeans sour=
ces into a different package hierarchy.  It is not mean for users of XmlBea=
ns.

Are you trying to change the packages that a schema compiles to?

- Eric

-----Original Message-----
From: Breese, Dustin [mailto:dustin.breese@test.com]
Sent: Friday, October 10, 2003 12:42 PM
To: xmlbeans-user@xml.test.com
Subject: noNamespace package alternatives


I'm using XmlBeans release 1 and have found the hidden -repackage
"from:to" option using scomp.  However, when trying to parse() my xml
and bind to it, it is throwing a class cast exception.  The only way I
can figure out how to get it to work is to leave all of my generated
sources in the "noNamespace" java package.

Is there any way around this or am I doing something wrong?

Thanks in advance,
Dustin


- ---------------------------------------------------------------------
To unsubscribe, e-mail:   xmlbeans-user-unsubscribe@xml.test.com
For additional commands, e-mail: xmlbeans-user-help@xml.test.com
Apache XMLBeans Project -- URL: http://xml.test.com/xmlbeans/


- ---------------------------------------------------------------------
To unsubscribe, e-mail:   xmlbeans-user-unsubscribe@xml.test.com
For additional commands, e-mail: xmlbeans-user-help@xml.test.com
Apache XMLBeans Project -- URL: http://xml.test.com/xmlbeans/



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
  p(m.method('create'),"INBOX/ENVELOPE"),
  cb("Create message using append") {       
    1.upto(1) { |i|
      m.append("INBOX/ENVELOPE",message.gsub(/REPLACEME/,i.to_s),[:Seen], Time.now) 
    }
    "Done"
  },   
  {'ENVELOPE' => 'package' }.sort { |a, b| a[1].to_s <=> b[1].to_s }.map do |x|
      IMAP.genFetchAction([Model::TARGETHOST, Model::IMAPSSL, true], testAccount, 'INBOX/ENVELOPE', x) 
  end,  
  p(m.method('delete'),"INBOX/ENVELOPE"),  
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
