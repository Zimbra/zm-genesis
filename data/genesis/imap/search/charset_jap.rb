#!/usr/bin/ruby -w
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2011 Zimbra
#
# Search charset test for ISO-2022-JP
if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 

require "net/imap"; require "action/imap" #Patch Net::IMAP library
 
require "model"

require "action/block"
require "action/zmprov"
require "action/proxy"
require "action/sendmail"
require "action/verify"


#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP Search Charset ISO-2022-JP test"

name = 'isearch'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s

testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

m = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)

include Action

# use http://kanjidict.stc.cx/recode.php for encondings

message = <<EOF.gsub(/\n/, "\r\n")
From: =?ISO-2022-JP?B?GyRCTG5CPCEhNUE/TRsoQg==?= <yoshito.testme@testme-ict.net>
To: <comtest01@test.testme.co.xy>
Date: Thu, 21 Apr 2011 14:50:05 +0900
Subject: =?ISO-2022-JP?B?GyRCOCE6dxsoQjI=?=
Message-ID: <20110421145005.03188468@secure-ict.net>
X-Mailer: WebMail V2.0IR5.1C
X-Priority: 3
MIME-Version: 1.0
Content-Type: text/plain; charset=ISO-2022-JP
Content-Transfer-Encoding: 7bit

\e$BLnB<!!5A?M\e(B

\e$B>.5\;3$5$s\e(B
REPLACEME
\e$B-!\e(B
\e$B-"\e(B
\e$B-5\e(B
\e$B".\e(B
\e$B=j:_CO\e(B \e$B5~ETI\5~ET;T2<5~6hEl1v>.O)9bARD.\e(B8-3
\e$B=jB0;v6H<T\e(B \e$B@>F|K\N95RE4F;!J\e(BJR\e$B@>F|K\!K\e(B
\e$BEl3$N95RE4F;!J\e(BJR\e$BEl3$!K\e(B


\e$B$I$&$>\e(B
--
 <askasuki@boo.com.net>
)
EOF

search_string = 'TEXT "' + ['1b'.hex].pack("C") + '$B5~ET' + ['1b'.hex].pack("C") + '(B"'

#Net::IMAP.debug = true
 
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
  p(m.method('create'),"INBOX/charset"), 
  cb("Create 3 messages") { 
    1.upto(3) { |i|
      m.append("INBOX/charset",message.gsub(/REPLACEME/,i.to_s),[:Seen], Time.now) 
    }
    "Done"
  }, 
  
  p(m.method('select'),"INBOX/charset"), 
  
  v(p(m.method('search'), search_string,'ISO-2022-JP'))do |mcaller, data|  
    mcaller.pass = (data.class == Array) && (data.size == 3)
  end,

  #check that nothing is found under anohter charsets
  %w[US-ASCII UTF-8].map do |x| 
    v(p(m.method('search'), search_string,x))do |mcaller, data|  
      mcaller.pass = (data[0] == nil)
    end
  end,

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

