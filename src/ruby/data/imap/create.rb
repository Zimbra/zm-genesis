#!/usr/bin/ruby -w
#
# = action/create.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# IMAP create  test cases
# 

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "net/imap"; require "action/imap" #Patch Net::IMAP library
require "model"

require "action/zmprov"
require "action/proxy"
require "action/sendmail"
require "action/verify"


#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP Create test"

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s 
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

mimap = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)

include Action 

 
#
# Setup
#
current.setup = [
 
]

#
# Execution
#
 

mailboxes = ["INBOX/one", "INBOX/two", "INBOX/three/three", "INBOX/five", "apple/&Jijo!"]
current.action = [  
  CreateAccount.new(testAccount.name,testAccount.password),
  if(Model::TARGETHOST.proxy) 
   CreateVerify.new(mimap, "INBOX/three/three", &Action::IMAP::ParseError)
  else 
   CreateVerify.new(mimap, "INBOX/three/three", &Action::IMAP::MustInAuthSelect)
  end, 
  Action::SendMail.new(testAccount.name,'DummyMessageOne'), 
  #Basic operation 
  p(mimap.method('login'),testAccount.name,testAccount.password),  
  mailboxes.map { |term|
    [CreateVerify.new(mimap, term), StatusVerify.new(mimap, term, ["UIDVALIDITY"])]     
  },  
  
  mailboxes.map { |term|
    p(mimap.method('delete'), term)
  },  
 
  #Error cases
  ["INBOX/", "INBOX", "Calendar/", "Contacts/", "Contacts/hi", "Junk/hi"].map { |term|
    CreateVerify.new(mimap, term, &Action::IMAP::CreateFailed) 
  },
  
  #Special folders
  ["Sent/hi", "Drafts/hi", "Trash/hi", "hi/INBOX"].map { |term|
    [CreateVerify.new(mimap, term), StatusVerify.new(mimap, term, ["UIDVALIDITY"]), p(mimap.method('delete'), term)]
  },
  
  #Tree operation
  # Both delete from parent and delete from child
  [lambda { | y, z | return y << y[-1]+'/'+ z }, lambda { | y, z| return y.unshift(y[0]+'/'+ z) }].map do |processor|  
    # The creation strings to be tested
    ["~peter/mail/&U,BTFw-/&ZeVnLIqe-", "INBOX/four/four", "orange/&U,BTFw-&ZeVnLIqe-", "he//", 'he\/'].map { |term|
      [CreateVerify.new(mimap, term),  #Create a folder
        term.split('/').inject([]) { |token, x|  #Construction delete sequence
          if(token.size == 0)
            [x]
          else
            processor.call(token, x)           
          end
        }.map { |tobedelete|       
          if(tobedelete != 'INBOX') #Can not delete INBOX
            DeleteVerify.new(mimap, tobedelete)
          else
            DeleteVerify.new(mimap, tobedelete, &Action::IMAP::DeleteFailed) 
          end 
        }
      ]
    }
  end,
  
  #Some error cases
  ["hi/", "hi/", "so:so", 'so"so', "so#{19.chr}so", "so#{20.chr}so", "so#{21.chr}so"].map { |term|
    CreateVerify.new(mimap, term, &Action::IMAP::CreateFailed)
  },   
   
 ]

#
# Tear Down
#
current.teardown = [     
  proxy(mimap.method('logout')),
  proxy(mimap.method('disconnect')),  
  DeleteAccount.new(testAccount.name)
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end 