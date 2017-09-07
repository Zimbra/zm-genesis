#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# IMAP Body Structure with 1 line message test, bug 2839
#
if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"
require "action/block"

require "action/zmprov"
require "action/proxy"
require "action/verify"
require "action/decorator"
require "net/imap"; require "action/imap" #Patch Net::IMAP library

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP Bug 2839"

name = 'ifetch'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

include Action
mimap = d

message = <<EOF
Message-ID: <6633803.1122314643238.JavaMail.liquid@qa04.liquidsys.com>
Date: Mon, 25 Jul 2005 11:04:03 -0700 (PDT)
From: REPLACEME
To: REPLACEME
Subject: sdsd
MIME-Version: 1.0
Content-Type: text/plain; charset=utf-8
Content-Transfer-Encoding: 7bit

sddsdd
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
                  cb("Imap connection initialization") do
                    mimap.object =  Net::IMAP.new(Model::TARGETHOST, *Model::TARGETHOST.imap)                                  
                  end,
                  p(mimap, 'login', testAccount.name, testAccount.password),
                  p(mimap, 'create',"INBOX/FETCHMIME"),
                  cb("Create 5 messages using append") {       
                    1.upto(1) { |i|
                      mimap.append("INBOX/FETCHMIME",message.gsub(/REPLACEME/,i.to_s),[:Seen], Time.now) 
                    }
                    "Done"
                  },  
                  v(cb("Fetch boundry check") do
                    mimap.select('INBOX/FETCHMIME')
                    mimap.fetch(1..1, 'BODYSTRUCTURE')
                  end) do |mcaller, data|
                    mcaller.pass = (data.first.attr['BODYSTRUCTURE']['lines'] == 1)
                  end,               
                  p(mimap, 'delete', "INBOX/FETCHMIME"),  
                 ]

#
# Tear Down
#
current.teardown = [     
  p(mimap, 'logout'),
  p(mimap, 'disconnect'),  
  DeleteAccount.new(testAccount.name)
]

if($0 == __FILE__)
  require 'engine/simple'
  
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run    
end
