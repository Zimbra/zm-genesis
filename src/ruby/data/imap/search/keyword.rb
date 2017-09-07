#!/usr/bin/ruby -w
#
# = data/imap/keyword.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# IMAP SEARCH keyword test cases
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
current.description = "IMAP Search Keyword test"

name = 'isearch'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
name = "admin" if ($0 == __FILE__)
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

m = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)

include Action

message = <<EOF.gsub(/\n/, "\r\n")
Subject: hello
From: genesis@test.org
To: genesis@ruby-lang.org

Sequence message REPLACEME
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
  p(m.method('create'),"INBOX/keyword"), 
  cb("Create 20 messages") { 
    flags = [:Draft, :Answered, :Deleted, :Flagged, :Seen, '$FORWARDED', 'JUNK', 'NONJUNK', 'NOTJUNK', 'DUMMY', 'NIL']
    0.upto(20) { |i|      
      m.append("INBOX/keyword",message.gsub(/REPLACEME/,i.to_s),[flags[i%flags.size]], Time.now) 
    }
    "Done"
  }, 
  p(m.method('select'),"INBOX/keyword"),   
  p(m.method('fetch'),1..21,['FLAGS']),
  
  [ %w[KEYWORD \SEEN],
    %w[UNKEYWORD \SEEN]].map do |x|
    SearchVerify.new(m, x, &IMAP::FetchParseError)
  end,   
  
  { %w[KEYWORD DUMMY] => (z = [10, 21]),
    %w[UNKEYWORD DUMMY] => (y = (w = (1..21).to_a) - z),    
    %w[NOT KEYWORD DUMMY] => y,
    %w[NOT UNKEYWORD DUMMY] => z,
    %w[OR NOT KEYWORD DUMMY KEYWORD DUMMY] => w,
    %w[KEYWORD NIL] => [11],
    %w[UNKEYWORD NIL] => w - [11]
  }.sort.map do |x|
     SearchVerify.new(m, x[0], x[1])
  end,
  
  { 'KEYWORD NIL' => 1,
    'UNKEYWORD NIL' => 20
  }.sort.map do |x|
    v(p(m.method('uid_search'),x[0])) do |mcaller, data |
      mcaller.pass = (data.class == Array) &&
        (data.size == x[1])
    end
  end,  
  p(m.method('delete'),"INBOX/keyword")
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