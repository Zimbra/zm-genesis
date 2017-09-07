#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$

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
Date: Fri, 01 Jan 2010 12:00 -0500
To: x@x.x
From: y@y.y
Subject: download on demand problem Marker1
MIME-Version: 1.0
Content-Type: message/rfc822

Date: Fri, 01 Jan 2012 12:00 -0500
To: y@y.y
From: x@x.x
Subject: Blast from the future Marker2
MIME-Version:1.0
Content-Type: text/plain

Do you know what to do when you see this message?
Marker3
EOF

expectations = {
                'BODY[TEXT]' => [false, true, true],
                'BODY[1]' => [false, true, true],
                'BODY[1.1]' => [false, false, true],
                'BODY[1.MIME]' => [true, false, false],
                'BODY[1.HEADER]' => [false, true, false],
                'BODY[1.TEXT]' => [false, false, true]
}

def check_expectations(response, key, expect)
  (response.include?('Marker1') == expect[key][0]) &&
  (response.include?('Marker2') == expect[key][1]) &&
  (response.include?('Marker3') == expect[key][2])
end
#Net::IMAP.debug=true 
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
    mimap.login(testAccount.name, testAccount.password)
    mimap.select('INBOX')
  end,
  cb("Create a message using append") do
      mimap.append("INBOX",message,[:Seen], Time.now) 
  end,
  expectations.each_key.map do |e|
    v(cb("fetch #{e}") do
      mimap.fetch(1..1, e)
    end) do |mcaller, data|
      mcaller.pass = check_expectations(data.first.attr[e], e, expectations)
    end
  end,             
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
