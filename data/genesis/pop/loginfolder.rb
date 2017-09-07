#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# POP login to folder other than INBOX
#

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"
require "action/block"
require "action/zmprov"
require "action/proxy" 
require "action/verify"
require "net/imap"; require "action/imap" #Patch Net::IMAP library
require "net/pop"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "POP Login to a folder"

name = File.expand_path(__FILE__).sub(/.*?(data\/)(genesis\/)?(zm)?/, 'zm').sub('.rb', '').gsub(/\/|\(|\)/, '')
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

mimap = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)
folder = 'testFolder'
loginFolder = '{in:' + folder + '}' 
pop = Net::POP3.new(Model::TARGETHOST, *Model::TARGETHOST.pop)

include Action

message = <<EOF.gsub(/\n/, "\r\n")
Subject: hello
From: genesis@test.org
To: genesis@ruby-lang.org

Sequence message REPLACEME
EOF

flags = [:Answered, :Draft, :Deleted, :Flagged, :Seen, '$FORWARDED', 'JUNK', 'NONJUNK', 'NOTJUNK', 'DUMMY', 'NIL']
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
  unless Model::TARGETHOST.proxy # support for Nginx is not implemented, see #27014
  [
    p(mimap.method('login'), testAccount.name, testAccount.password),
    p(mimap.method('create'), folder),
    p(mimap.method('select'), folder),
    cb("Create 3 messages") do
      0.upto(2) do |i|                
        cflags = [flags[(i+4)%flags.size]]
        mimap.append(folder, message.gsub(/REPLACEME/,i.to_s),cflags, Time.now)    
        "Done"
      end
    end,
     
    #pop login with folder
    v(cb("Simple 20 mails fetch") {
      response = []   
      pop.start(testAccount.name + loginFolder, testAccount.password)
       
      if pop.mails.empty?
        response = ["Failure no mail"]
        exitstatus = 1
      else
        pop.each_mail { |m| response.push(m.pop) }  
        exitstatus = 0
      end       
      [exitstatus, response]
    }) do |mcaller, data|
      mcaller.pass = (data[0] == 0)
    end, 
    
    # empty mailbox
    p(mimap.method('select'), folder),
    p(mimap.method('store'), (1..-1), "FLAGS", [:DELETED]),
    p(mimap.method('close')),   
    
    # empty mailbox fetch
    v(cb("Simple 20 mails fetch") {
      response = ["Success"]  
      exitstatus = 0
      pop.finish 
      pop.start(testAccount.name  + loginFolder, testAccount.password)
      if not pop.mails.empty?
        response = ["Failure not empty"]
        pop.each_mail { |m| response.push(m.pop) }  
        exitstatus = 1
      end       
      [exitstatus, response]
    }) do |mcaller, data|
      mcaller.pass = (data[0] == 0)
    end, 
    
    p(mimap.method('logout')),
  ]
  end
]

#
# Tear Down
#
current.teardown = [     
  proxy(mimap.method('disconnect')),
  DeleteAccount.new(testAccount.name)
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end
