#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2011 Zimbra
#
# IMAP store test cases
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
current.description = "IMAP Store test"

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
 
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
  
]

flags = {:Answered => [:Answered], :Draft => [], :Deleted => [:Deleted], :Flagged => [:Flagged], :Seen => [:Seen], 
          '$FORWARDED' => ['$Forwarded', 'Forwarded'], 'JUNK' => ['Junk', '$Junk'], 'NONJUNK' => ['$NotJunk', 'NotJunk', 'NonJunk'], 
          'NOTJUNK' => ['$NotJunk', 'NotJunk', 'NonJunk'], 
          'DUMMY' => ['DUMMY'], 'NIL' => ['NIL']}
          
flagskeys = flags.keys    
 
#
# Execution
#
current.action = [  
  CreateAccount.new(testAccount.name,testAccount.password),
  p(m.method('login'),testAccount.name,testAccount.password),
  p(m.method('create'),"INBOX/store"), 
  cb("Create 20 messages") {     
    0.upto(19) { |i|                
      cflags = [flagskeys[(i+4)%flagskeys.size]]
      m.append("INBOX/store",message.gsub(/REPLACEME/,i.to_s),cflags, Time.now)    
      "Done"
    }
  },  
  
  #So we have 20 messages with different states
  p(m.method('select'),'INBOX/store'),  
  p(m.method('fetch'), 1..20, ['FLAGS']),  
 
  Array.new(20) do |index|
    cflags = [flagskeys[index%flagskeys.size]]  
    vflags = cflags.map do |x|
      flags[x]
    end.flatten     
    
    [
      StoreVerify.new(m, index+1, "FLAGS", cflags, vflags),
      StoreVerify.new(m, index+1, "FLAGS.SILENT", cflags, vflags) do |mcaller, data| 
        mcaller.pass = (data.class == NilClass)
      end
    ]
  end, 
  
  Array.new(20) do |index|
    cflags = Array.new(2) do |x|
      flagskeys[(x+index)%flagskeys.size]
    end
    vflags = cflags.map do |x|
      flags[x]
    end.flatten    
    
    [ 
      StoreVerify.new(m, index+1, "FLAGS", cflags, vflags),
      StoreVerify.new(m, index+1, "FLAGS.SILENT", cflags, vflags) do |mcaller, data| 
        mcaller.pass = (data.class == NilClass)
      end
    ]
  end,
  
  
  Array.new(20) do |index|
    cflags = Array.new(3) do |x|
      flagskeys[(x+index+1)%flagskeys.size]
    end
    vflags = flags[flagskeys[index%flagskeys.size]]     
    if not([9, 20].include?(index+1)) #bug in test logic need to clean up later
      [
        StoreVerify.new(m, index+1, "-FLAGS", cflags, [:Recent]),
        StoreVerify.new(m, index+1, "-FLAGS.SILENT", cflags, [:Recent]) do |mcaller, data|
          mcaller.pass = (data.class == NilClass)
        end
      ] 
    end     
  end.compact, 
     
  # Can not store recent
  StoreVerify.new(m, 1, "FLAGS", [:Recent], &IMAP::InvalidFlag), 
  
  # empty store flag is acceptable
  StoreVerify.new(m, 1, "FLAGS", [:Seen], [:Seen]),
  StoreVerify.new(m, 1, "+FLAGS", [], []),
  p(m.method('fetch'), 1, "FLAGS"),  
   
  #p(m.method('select'), "INBOX/store"),
  #p(m.method('delete'), "INBOX/store"), 
  v(cb("Bug 29709 -FLAGS on nonexisting flag NPE", 15) do
    m.store(1, "-FLAGS", ['thisissowrong'])
  end) do |mcaller, data|
    mcaller.pass = data.class == Array && data.first.class == Net::IMAP::FetchData
  end,
  p(m.method('logout'))
   
]

#
# Tear Down
#
current.teardown = [
  p(m.method('disconnect')),
  DeleteAccount.new(testAccount.name)
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end
