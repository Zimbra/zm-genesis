#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# Bad Mime Test bug #28629
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
current.description = "IMAP Bad Mimec test"

name = 'ifetch'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

m = Net::IMAP.new(Model::TARGETHOST, *Model::TARGETHOST.imap)

include Action

message = <<EOF
Return-Path: dummy@zimbra.com
Received: from zimbra01.test.com (LHLO zimbra01.test.com) (127.0.0.1) by
 zimbra01.test.com with LMTP; Mon, 16 Jun 2008 18:04:39 +0200 (CEST)
Received: from localhost (localhost [127.0.0.1])
  by zimbra01.test.com (Postfix) with ESMTP id 1BDE08C462
  for <sj@test.com>; Mon, 16 Jun 2008 18:04:39 +0200 (CEST)
X-Virus-Scanned: amavisd-new at 
X-Spam-Flag: NO
X-Spam-Score: -0.173
X-Spam-Level: 
X-Spam-Status: No, score=-0.173 tagged_above=-10 required=6.6
  tests=[AWL=-0.584, BAYES_00=-2.599, HTML_IMAGE_ONLY_24=1.552,
  HTML_MESSAGE=0.001, MIME_HTML_ONLY=1.457]
Received: from zimbra01.test.com ([127.0.0.1])
  by localhost (zimbra01.test.com [127.0.0.1]) (amavisd-new, port 10024)
  with ESMTP id jvwRILvpklQE for <sj@test.com>;
  Mon, 16 Jun 2008 18:04:37 +0200 (CEST)
Received: from mxout01.test.com (mxout01.test.com [127.0.0.1])
  by zimbra01.test.com (Postfix) with ESMTP id 3A3EF8C430
  for <sj@test.com>; Mon, 16 Jun 2008 18:04:37 +0200 (CEST)
X-IronPort-AV: E=Sophos;i="4.27,653,1204498800"; 
   d="scan'208,217,147";a="800817"
Received: from gmp-eb-inf-2.testme.com ([192.18.6.24])
  by mxfilter01.test.com with ESMTP/TLS/EDH-RSA-DES-CBC3-SHA; 16 Jun 2008 18:04:39 +0200
Received: from fe-emea-09.testme.com (gmp-eb-lb-2-fe1.eu.testme.com [127.0.0.1])
  by gmp-eb-inf-2.testme.com (8.13.7+Sun/8.12.9) with ESMTP id m5GG4bhI025390
  for <sj@test.com>; Mon, 16 Jun 2008 16:04:37 GMT
Received: from conversion-daemon.fe-emea-09.testme.com by fe-emea-09.testme.com
 (Sun Java System Messaging Server 6.2-8.04 (built Feb 28 2007))
 id <0K2K00401BZ53U00@fe-emea-09.testme.com>
 (original mail from dummy@zimbra.com) for sj@test.com; Mon,
 16 Jun 2008 17:04:37 +0100 (BST)
Received: from [129.159.156.174] by fe-emea-09.testme.com
 (Sun Java System Messaging Server 6.2-8.04 (built Feb 28 2007))
 with ESMTPSA id <0K2K00N4HCNA1L80@fe-emea-09.testme.com>; Mon,
 16 Jun 2008 17:04:23 +0100 (BST)
Date: Mon, 16 Jun 2008 18:04:08 +0200
From: Kristian Test <dummy@zimbra.com>
Subject: 1564 =?ISO-8859-1?Q?St=E5ende_CAD_Netic_EDU_=26_1565_?=
 =?ISO-8859-1?Q?St=E5ende_CAD_Netic_SKI?=
Sender: dummy@zimbra.com
To: rick@blue.local 
Message-id: <48568EF8.2020509@test.com>
MIME-version: 1.0
Content-type: multipart/mixed; boundary="Boundary_(ID_jRy0SHXieEc+c/xy41qExA)"
User-Agent: Thunderbird 2.0.0.14 (Windows/20080421)

This is a multi-part message in MIME format.

--Boundary_(ID_jRy0SHXieEc+c/xy41qExA)
Content-type: multipart/related; boundary="Boundary_(ID_t0TPEom9Aq6SfBHj4eA7Gg)"


--Boundary_(ID_t0TPEom9Aq6SfBHj4eA7Gg)
Content-type: text/html; charset=ISO-8859-1
Content-transfer-encoding: 7BIT

<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
</head>
<body bgcolor="#ffffff" text="#000000">
Hej Steen,<br>
<br>
Vedh&aelig;ftet st&aring;ende CAD p&aring; EDU &amp; SKI d&aelig;kker perioden&nbsp; 16 juni&nbsp; 2008&nbsp;
-&nbsp; 30 sep.
2008. <br>
Disse CAD'er kan genbruges p&aring; alle henholdsvis EDU og SKI kunder i
indev&aelig;rende periode. <br>
<b><u><small><br>
NB! Der tages forbehold for l&oslash;bende &aelig;ndringer. Eventuelle &aelig;ndringer vil
blive oplyst.</small></u></b><br>
<br>
Tak for dine forslag til forbedringer. Jeg kigger p&aring; dem samme med
Brian. Men indtil videre h&aring;ber jeg disse st&aring;ende CAD'er kan hj&aelig;lpe.<br>
<br>
Hilsen<br>
Kristian
<div class="moz-signature">-- <br>
<meta http-equiv="CONTENT-TYPE" content="text/html; ">
<title></title>
<meta name="GENERATOR" content="StarOffice 8  (Win32)">
<meta name="CREATED" content="20080110;15033500">
<meta name="CHANGED" content="20080211;12554735">
<style type="text/css">
  <!--
    @page { size: 21cm 29.7cm }
  -->
  </style>
<table style="page-break-before: always;" border="0" cellpadding="0"
 cellspacing="0" width="500">
  <tbody>
    <tr valign="top">
      <td height="121" width="136">
      <p><a href="http://www.testme.com/"><img
 src="cid:part1.01080606.06050105@test.com" name="graphics1"
 align="bottom" border="0" height="121" width="136"></a></p>
      </td>
      <td width="364">
      <p><font size="2"><font size="2"><span style="">Kristian Bergmann
Siim </span></font><font size="2"><br>
      </font>Sales Controller</font></p>
      <p><font size="2">Sun Microsystems Danmark A/S<br>
Phone: +45 45565021<br>
Mobile: +45 23384021<br>
Email: <a class="moz-txt-link-abbreviated" href="mailto:dummy@zimbra.com">dummy@zimbra.com</a></font></p>
      </td>
    </tr>
    <tr>
      <td colspan="2" height="26" valign="top">
      <p><a href="http://www.testme.com/"><img
 src="cid:part2.02060801.03050908@test.com" name="graphics2"
 align="bottom" border="0" height="26" width="454"></a></p>
      </td>
    </tr>
  </tbody>
</table>
<p><br>
<br>
</p>
</div>
</body>
</html>

--Boundary_(ID_t0TPEom9Aq6SfBHj4eA7Gg)
Content-id: <part1.01080606.06050105@test.com>
Content-type: image/gif; name=graphics1
Content-transfer-encoding: BASE64
Content-disposition: inline; filename=graphics1

R0lGODlhiAB5AMQAALTE18vW5HmWtTRmjGWHqv///yVehaa5zythiJOqxYKdu012
f0AAU03wOd0nGgDBeHmbm1+ykj7+qeYA6Rtg+9SXgAAA8HCfo9bwGCACmkwuLA4U
AQIhaL0OevCDIAyhCEdIwhImTwB0QyEKi7fCAKhwbgJooQtnmMIZrlCGL6zbC2VI
QxjejYc+1GEPa2i3QtUwh0PEoQmXyMQmOvGJUGReDKdIxSpa8YpYzKIWt8jFLnrx
i2C0IgIeEMaaMprxjGhMoxrXyMY2uvGNcIyjHOdIxzra8Y54zKMe98jHPvrxj3Ec
gAAESchBGrKQiDQkIBfJyEY68pFtHIAkJ0nJSlrykpjMpCY3yclOevKToAylKEdJ
ylKa8pSoTKUqV8nKVrrylbCMpSxnScta2vKWuMylLnfJy1768pfADKYwh0nMYhrz
mMhMpjKXycxmOvOZ0IymNJcZAgA7

--Boundary_(ID_t0TPEom9Aq6SfBHj4eA7Gg)--

--Boundary_(ID_jRy0SHXieEc+c/xy41qExA)
Content-type: application/pdf;
 name="1565 =?ISO-8859-1?Q?ST=C5ENDE_CAD_Netic_SKI=2Epdf?="
Content-transfer-encoding: BASE64
Content-disposition: inline;
 filename="1565 =?ISO-8859-1?Q?ST=C5ENDE_CAD_Netic_SKI=2Epdf?=";
 filename*1*=%20%4E%65%74%69%63%20%53%4B%49%2E%70%64%66;
 filename*0*=ISO-8859-1''%31%35%36%35%20%53%54%C5%45%4E%44%45%20%43%41%44

JVBERi0xLjQKJcOkw7zDtsOfCjIgMCBvYmoKPDwvTGVuZ3RoIDMgMCBSL0ZpbHRl
IAowMDAwMDY1MDI2IDAwMDAwIG4gCjAwMDAwNjUwNzkgMDAwMDAgbiAKMDAwMDA2
NTUyNSAwMDAwMCBuIAowMDAwMDY1NjA5IDAwMDAwIG4gCnRyYWlsZXIKPDwvU2l6
ZSAyNy9Sb290IDI1IDAgUgovSW5mbyAyNiAwIFIKL0lEIFsgPDBGRERFNjdENzg2
ODk2RUQ1NzhGOUJFMDRCRjQ0OTY4Pgo8MEZEREU2N0Q3ODY4OTZFRDU3OEY5QkUw
NEJGNDQ5Njg+IF0KPj4Kc3RhcnR4cmVmCjY1NzcyCiUlRU9GCg==

--Boundary_(ID_jRy0SHXieEc+c/xy41qExA)
Content-type: application/pdf;
 name="1564 =?ISO-8859-1?Q?ST=C5ENDE_CAD_Netic_EDU=2Epdf?="
Content-transfer-encoding: BASE64
Content-disposition: inline;
 filename="1564 =?ISO-8859-1?Q?ST=C5ENDE_CAD_Netic_EDU=2Epdf?=";
 filename*1*=%20%4E%65%74%69%63%20%45%44%55%2E%70%64%66;
 filename*0*=ISO-8859-1''%31%35%36%34%20%53%54%C5%45%4E%44%45%20%43%41%44

JVBERi0xLjQKJcOkw7zDtsOfCjIgMCBvYmoKPDwvTGVuZ3RoIDMgMCBSL0ZpbHRl
ci9GbGF0ZURlY29kZT4+CnN0cmVhbQp4nL1azY4juQ2+91PUeYE4IvVbwCKA3bZz
nmSAPECSDRBkAuxe9vVDSZTIUqns9qAnM0B3syhK4q8+qsosv7/9upjFnGDxqz/Z
IDAwMDAwIG4gCjAwMDAwNjY4OTEgMDAwMDAgbiAKMDAwMDA2NzMzNyAwMDAwMCBu
IAowMDAwMDY3NDIxIDAwMDAwIG4gCnRyYWlsZXIKPDwvU2l6ZSAyNy9Sb290IDI1
IDAgUgovSW5mbyAyNiAwIFIKL0lEIFsgPEUxRjExMUU1MjlDREM5Q0FBMjQ3OUE0
MTYwNTNFNzA0Pgo8RTFGMTExRTUyOUNEQzlDQUEyNDc5QTQxNjA1M0U3MDQ+IF0K
Pj4Kc3RhcnR4cmVmCjY3NTg0CiUlRU9GCg==

--Boundary_(ID_jRy0SHXieEc+c/xy41qExA)--
EOF
 
#
# Setup
#
current.setup = [
 
]

#
# Execution
#
current.action = [  
  CreateAccount.new(testAccount.name,testAccount.password),
  p(m.method('login'),testAccount.name,testAccount.password),
  p(m.method('create'),"INBOX/FETCHBASIC"),
  cb("Create 2 messages using append") {       
    1.upto(2) { |i|
      m.append("INBOX/FETCHBASIC",message.gsub(/REPLACEME/,i.to_s),[:Seen], Time.now) 
    }
    "Done"
  },
  v(RunCommand.new('tail', 
    Command::ZIMBRAUSER, '-1000', File.join(Command::ZIMBRAPATH,'log','mailbox.log'))) do |mcaller, data|
      mcaller.pass = !data[1].include?('NullPointerException')
   end,   
  p(m.method('delete'),"INBOX/FETCHBASIC"),  
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
