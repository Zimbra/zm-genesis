#!/bin/env ruby
#
# = volume/add.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# ZMVolume basic test
# 

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"
require "action/block"
require "action/command"

require "action/sendmail" 
require "action/zmvolume"
require "action/zmprov"
require "action/proxy"
require "action/verify"
require "net/imap"; require "action/imap" #Patch Net::IMAP library

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "ZMVolume Add test"

name = 'zmvolume'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
name = "admin" if ($0 == __FILE__)
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)
 
include Action
 
#
# Setup
#
current.setup = [
   CreateAccount.new(testAccount.name,testAccount.password) 
]

message = <<EOF.gsub(/\n/, "\r\n")
Subject: hello
From: genesis@test.org
To: REPLACEME

This message is for MARKINDEX
05-10-2005 14:19:13 [4584]: Creating / starting 1 worker threads
05-10-2005 14:19:13 [4584]: Dispatching work to worker threads
05-10-2005 14:19:13 [3900]: Worker thread started
05-10-2005 14:19:13 [4584]: Notifying threads to exit
05-10-2005 14:19:13 [3900]: Waiting for work
05-10-2005 14:19:13 [3900]: Work arrived.../o=LIQUIDSYS/ou=first administrative group/cn=Recipients/cn=bhwang bhwang@xserve1.liquidsys.com
05-10-2005 14:19:13 [3900]: Logging on to zimbra server
05-10-2005 14:19:13 [3900]: Opening other users store
05-10-2005 14:19:13 [3900]: Replicating folder hierarchy
05-10-2005 14:19:15 [3900]: (FR): Entering folder: /
05-10-2005 14:19:15 [3900]: (FR): Detected special folder (root)
05-10-2005 14:19:15 [3900]: (FR): Child folders will be processed
05-10-2005 14:19:15 [3900]: (FR): Entering folder: Calendar
05-10-2005 14:19:15 [3900]: (FR): Detected special folder (calendar)
05-10-2005 14:19:15 [3900]: (FR): Child folders will be processed
05-10-2005 14:19:15 [3900]: (FR): Leaving folder Calendar
05-10-2005 14:19:15 [3900]: (FR): Entering folder: Contacts
05-10-2005 14:19:15 [3900]: (FR): Detected special folder (contacts)
05-10-2005 14:19:15 [3900]: (FR): Child folders will be processed
05-10-2005 14:19:15 [3900]: (FR): Leaving folder Contacts
05-10-2005 14:19:15 [3900]: (FR): Entering folder: Deleted Items
05-10-2005 14:19:15 [3900]: (FR): Detected special folder (trash)
05-10-2005 14:19:15 [3900]: (FR): Child folders will be processed
05-10-2005 14:19:15 [3900]: (FR): Leaving folder Deleted Items
05-10-2005 14:19:15 [3900]: (FR): Entering folder: Drafts
05-10-2005 14:19:15 [3900]: (FR): Detected special folder (drafts)
05-10-2005 14:19:15 [3900]: (FR): Child folders will be processed
05-10-2005 14:19:15 [3900]: (FR): Leaving folder Drafts
05-10-2005 14:19:15 [3900]: (FR): Entering folder: Inbox
05-10-2005 14:19:15 [3900]: (FR): Detected special folder (inbox)
05-10-2005 14:19:15 [3900]: (FR): Child folders will be processed
05-10-2005 14:19:15 [3900]: (FR): Entering folder: ''
05-10-2005 14:19:15 [3900]: (FR): Handling user-defined folder
05-10-2005 14:19:15 [3900]: (FR): Folder does not exist on zimbra, attempting to create it
05-10-2005 14:19:15 [3900]: (FR): Created folder '' with id 257 with parent id 2
05-10-2005 14:19:15 [3900]: (FR): Created a new folder '' - fid is 257
05-10-2005 14:19:15 [3900]: (FR): Child folders will be processed
05-10-2005 14:19:15 [3900]: (FR): Leaving folder ''
05-10-2005 14:19:15 [3900]: (FR): Entering folder: ""
05-10-2005 14:19:15 [3900]: (FR): Handling user-defined folder
05-10-2005 14:19:15 [3900]: (FR): Folder does not exist on zimbra, attempting to create it
05-10-2005 14:19:15 [3900]: (FR): Created folder ''{0100cd0076f311ff32419ca0dc637b5563b90000028000130000} with id 258 with parent id 2
05-10-2005 14:19:15 [3900]: (FR): Created a new folder ''{0100cd0076f311ff32419ca0dc637b5563b90000028000130000} - fid is 258
05-10-2005 14:19:15 [3900]: (FR): Child folders will be processed
05-10-2005 14:19:15 [3900]: (FR): Leaving folder ""
05-10-2005 14:19:15 [3900]: (FR): Entering folder: //
05-10-2005 14:19:15 [3900]: (FR): Handling user-defined folder
05-10-2005 14:19:15 [3900]: (FR): Folder does not exist on zimbra, attempting to create it
05-10-2005 14:19:15 [3900]: (FR): Created folder -\{0100cd0076f311ff32419ca0dc637b5563b90000028000140000} with id 259 with parent id 2
05-10-2005 14:19:15 [3900]: (FR): Created a new folder -\{0100cd0076f311ff32419ca0dc637b5563b90000028000140000} - fid is 259
05-10-2005 14:19:15 [3900]: (FR): Child folders will be processed
05-10-2005 14:19:15 [3900]: (FR): Leaving folder //
05-10-2005 14:19:15 [3900]: (FR): Entering folder: ::
05-10-2005 14:19:15 [3900]: (FR): Handling user-defined folder
05-10-2005 14:19:15 [3900]: (FR): Folder does not exist on zimbra, attempting to create it
05-10-2005 14:19:15 [3900]: (FR): Created folder ||{0100cd0076f311ff32419ca0dc637b5563b90000028000120000} with id 260 with parent id 2
05-10-2005 14:19:15 [3900]: (FR): Created a new folder ||{0100cd0076f311ff32419ca0dc637b5563b90000028000120000} - fid is 260
05-10-2005 14:19:15 [3900]: (FR): Child folders will be processed
05-10-2005 14:19:15 [3900]: (FR): Leaving folder ::
05-10-2005 14:19:15 [3900]: (FR): Entering folder: -\
05-10-2005 14:19:15 [3900]: (FR): Handling user-defined folder
05-10-2005 14:19:15 [3900]: (FR): Folder does not exist on zimbra, attempting to create it
05-10-2005 14:19:15 [3900]: (FR): Created folder -\ with id 261 with parent id 2
05-10-2005 14:19:15 [3900]: (FR): Created a new folder -\ - fid is 261
05-10-2005 14:19:15 [3900]: (FR): Child folders will be processed
05-10-2005 14:19:15 [3900]: (FR): Leaving folder -\
05-10-2005 14:19:15 [3900]: (FR): Entering folder: \\hithere
05-10-2005 14:19:15 [3900]: (FR): Handling user-defined folder
05-10-2005 14:19:15 [3900]: (FR): Folder does not exist on zimbra, attempting to create it

05-10-2005 14:19:15 [3900]: (FR): Created folder -\hithere{0100cd0076f311ff32419ca0dc637b5563b90000028000150000} with id 262 with parent id 2

05-10-2005 14:19:15 [3900]: (FR): Created a new folder -\hithere{0100cd0076f311ff32419ca0dc637b5563b90000028000150000} - fid is 262

05-10-2005 14:19:15 [3900]: (FR): Child folders will be processed

05-10-2005 14:19:15 [3900]: (FR): Leaving folder \\hithere

05-10-2005 14:19:15 [3900]: (FR): Entering folder: -\hithere

05-10-2005 14:19:15 [3900]: (FR): Handling user-defined folder

05-10-2005 14:19:15 [3900]: (FR): Folder does not exist on zimbra, attempting to create it

05-10-2005 14:19:15 [3900]: (FR): Created folder -\hithere with id 263 with parent id 2

05-10-2005 14:19:15 [3900]: (FR): Created a new folder -\hithere - fid is 263

05-10-2005 14:19:15 [3900]: (FR): Child folders will be processed

05-10-2005 14:19:15 [3900]: (FR): Leaving folder -\hithere

05-10-2005 14:19:15 [3900]: (FR): Entering folder: ||

05-10-2005 14:19:15 [3900]: (FR): Handling user-defined folder

05-10-2005 14:19:15 [3900]: (FR): Folder does not exist on zimbra, attempting to create it

05-10-2005 14:19:16 [3900]: (FR): Created folder || with id 264 with parent id 2

05-10-2005 14:19:16 [3900]: (FR): Created a new folder || - fid is 264

05-10-2005 14:19:16 [3900]: (FR): Child folders will be processed

05-10-2005 14:19:16 [3900]: (FR): Leaving folder ||

05-10-2005 14:19:16 [3900]: (FR): Entering folder: bugs

05-10-2005 14:19:16 [3900]: (FR): Handling user-defined folder

05-10-2005 14:19:16 [3900]: (FR): Folder does not exist on zimbra, attempting to create it

05-10-2005 14:19:16 [3900]: (FR): Created folder bugs with id 265 with parent id 2

05-10-2005 14:19:16 [3900]: (FR): Created a new folder bugs - fid is 265

05-10-2005 14:19:16 [3900]: (FR): Child folders will be processed

05-10-2005 14:19:16 [3900]: (FR): Leaving folder bugs

05-10-2005 14:19:16 [3900]: (FR): Entering folder: buildserver

05-10-2005 14:19:16 [3900]: (FR): Handling user-defined folder

05-10-2005 14:19:16 [3900]: (FR): Folder does not exist on zimbra, attempting to create it

05-10-2005 14:19:16 [3900]: (FR): Created folder buildserver with id 266 with parent id 2

05-10-2005 14:19:16 [3900]: (FR): Created a new folder buildserver - fid is 266

05-10-2005 14:19:16 [3900]: (FR): Child folders will be processed

05-10-2005 14:19:16 [3900]: (FR): Entering folder: ocaml

05-10-2005 14:19:16 [3900]: (FR): Handling user-defined folder

05-10-2005 14:19:16 [3900]: (FR): Folder does not exist on zimbra, attempting to create it

05-10-2005 14:19:16 [3900]: (FR): Created folder ocaml with id 267 with parent id 266

05-10-2005 14:19:16 [3900]: (FR): Created a new folder ocaml - fid is 267

05-10-2005 14:19:16 [3900]: (FR): Child folders will be processed

05-10-2005 14:19:16 [3900]: (FR): Leaving folder ocaml

05-10-2005 14:19:16 [3900]: (FR): Leaving folder buildserver

05-10-2005 14:19:16 [3900]: (FR): Entering folder: hi

05-10-2005 14:19:16 [3900]: (FR): Handling user-defined folder

05-10-2005 14:19:16 [3900]: (FR): Folder does not exist on zimbra, attempting to create it

05-10-2005 14:19:16 [3900]: (FR): Created folder hi with id 268 with parent id 2

05-10-2005 14:19:16 [3900]: (FR): Created a new folder hi - fid is 268

05-10-2005 14:19:16 [3900]: (FR): Child folders will be processed

05-10-2005 14:19:16 [3900]: (FR): Leaving folder hi

05-10-2005 14:19:16 [3900]: (FR): Entering folder: python-announce

05-10-2005 14:19:16 [3900]: (FR): Handling user-defined folder

05-10-2005 14:19:16 [3900]: (FR): Folder does not exist on zimbra, attempting to create it

05-10-2005 14:19:16 [3900]: (FR): Created folder python-announce with id 269 with parent id 2

05-10-2005 14:19:16 [3900]: (FR): Created a new folder python-announce - fid is 269

05-10-2005 14:19:16 [3900]: (FR): Child folders will be processed

05-10-2005 14:19:16 [3900]: (FR): Leaving folder python-announce

05-10-2005 14:19:16 [3900]: (FR): Entering folder: ruby

05-10-2005 14:19:16 [3900]: (FR): Handling user-defined folder

05-10-2005 14:19:16 [3900]: (FR): Folder does not exist on zimbra, attempting to create it

05-10-2005 14:19:16 [3900]: (FR): Created folder ruby with id 270 with parent id 2

05-10-2005 14:19:16 [3900]: (FR): Created a new folder ruby - fid is 270

05-10-2005 14:19:16 [3900]: (FR): Child folders will be processed

05-10-2005 14:19:16 [3900]: (FR): Leaving folder ruby

05-10-2005 14:19:16 [3900]: (FR): Entering folder: support

05-10-2005 14:19:16 [3900]: (FR): Handling user-defined folder

05-10-2005 14:19:16 [3900]: (FR): Folder does not exist on zimbra, attempting to create it

05-10-2005 14:19:16 [3900]: (FR): Created folder support with id 271 with parent id 2

05-10-2005 14:19:16 [3900]: (FR): Created a new folder support - fid is 271

05-10-2005 14:19:16 [3900]: (FR): Child folders will be processed

05-10-2005 14:19:16 [3900]: (FR): Leaving folder support

05-10-2005 14:19:16 [3900]: (FR): Leaving folder Inbox

05-10-2005 14:19:16 [3900]: (FR): Entering folder: Journal

05-10-2005 14:19:16 [3900]: (FR): Handling user-defined folder

05-10-2005 14:19:16 [3900]: (FR): Folder does not exist on zimbra, attempting to create it

05-10-2005 14:19:16 [3900]: (FR): Created folder Journal with id 272 with parent id 1

05-10-2005 14:19:16 [3900]: (FR): Created a new folder Journal - fid is 272

05-10-2005 14:19:16 [3900]: (FR): Child folders will be processed

05-10-2005 14:19:16 [3900]: (FR): Leaving folder Journal

05-10-2005 14:19:16 [3900]: (FR): Entering folder: Junk E-mail

05-10-2005 14:19:16 [3900]: (FR): Detected special folder (spam)

05-10-2005 14:19:16 [3900]: (FR): Child folders will be processed

05-10-2005 14:19:16 [3900]: (FR): Leaving folder Junk E-mail

05-10-2005 14:19:16 [3900]: (FR): Entering folder: Notes

05-10-2005 14:19:16 [3900]: (FR): Handling user-defined folder

05-10-2005 14:19:16 [3900]: (FR): Folder does not exist on zimbra, attempting to create it

05-10-2005 14:19:16 [3900]: (FR): Created folder Notes with id 273 with parent id 1

05-10-2005 14:19:16 [3900]: (FR): Created a new folder Notes - fid is 273

05-10-2005 14:19:16 [3900]: (FR): Child folders will be processed

05-10-2005 14:19:16 [3900]: (FR): Leaving folder Notes

05-10-2005 14:19:16 [3900]: (FR): Entering folder: Outbox

05-10-2005 14:19:16 [3900]: (FR): Handling user-defined folder

05-10-2005 14:19:16 [3900]: (FR): Folder does not exist on zimbra, attempting to create it

05-10-2005 14:19:16 [3900]: (FR): Created folder Outbox with id 274 with parent id 1

05-10-2005 14:19:16 [3900]: (FR): Created a new folder Outbox - fid is 274

05-10-2005 14:19:16 [3900]: (FR): Child folders will be processed

05-10-2005 14:19:16 [3900]: (FR): Leaving folder Outbox

05-10-2005 14:19:16 [3900]: (FR): Entering folder: quarantine

05-10-2005 14:19:16 [3900]: (FR): Handling user-defined folder

05-10-2005 14:19:16 [3900]: (FR): Folder does not exist on zimbra, attempting to create it

05-10-2005 14:19:17 [3900]: (FR): Created folder quarantine with id 275 with parent id 1

05-10-2005 14:19:17 [3900]: (FR): Created a new folder quarantine - fid is 275

05-10-2005 14:19:17 [3900]: (FR): Child folders will be processed

05-10-2005 14:19:17 [3900]: (FR): Leaving folder quarantine

05-10-2005 14:19:17 [3900]: (FR): Entering folder: Sent

05-10-2005 14:19:17 [3900]: (FR): Handling user-defined folder

05-10-2005 14:19:17 [3900]: (FR): Folder does not exist on zimbra, attempting to create it

05-10-2005 14:19:17 [3900]: (FR): Created folder Sent{0100cd0076f311ff32419ca0dc637b5563b90000022100140000} with id 276 with parent id 1

05-10-2005 14:19:17 [3900]: (FR): Created a new folder Sent{0100cd0076f311ff32419ca0dc637b5563b90000022100140000} - fid is 276

05-10-2005 14:19:17 [3900]: (FR): Child folders will be processed

05-10-2005 14:19:17 [3900]: (FR): Leaving folder Sent

05-10-2005 14:19:17 [3900]: (FR): Entering folder: Sent Items

05-10-2005 14:19:17 [3900]: (FR): Detected special folder (sent)

05-10-2005 14:19:17 [3900]: (FR): Child folders will be processed
EOF

module Action
  def Action.curStoragePath(x, mfilePath)
    if(x == 'primaryMessage')
      mfilePath
    else
      File.join(Command::ZIMBRAPATH,'store')
    end
  end
end
#
# Execution
#
counter = 0
m = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)

cid = Object.new
class << cid
  attr :id, true
end

current.action = [
  #Basic Creation Test
  LoginVerify.new(m, testAccount.name, testAccount.password),
  
  ['index', 'primaryMessage', 'secondaryMessage'].map do |x|      
    ['true', 'false'].map do |y| 
      counter = counter + 1 
      mfilePath = File.join(Command::ZIMBRAPATH, "store#{x}#{y}#{counter}")      
      msize = 0
      [
      
        ZMVolumeHelper.genCreateSet(mfilePath = File.join(Command::ZIMBRAPATH, testPath = "name#{counter}"),  testPath, x),     
        ZMVolumeHelper.genSendVerify(testAccount.name, Action.curStoragePath(x, mfilePath), message.gsub(/REPLACEME/, testAccount.name).
          gsub(/MARKINDEX/, "type #{x} compress #{y} path #{mfilePath} counter #{counter}")), 
 
        # Accessiblity check should able to search and fetch from IMAP          
        p(m.method('select'),"INBOX"),
        (1..counter).to_a.map do |whichmail|
          [
            FetchVerify.new(m, whichmail, 'RFC822.TEXT', "counter #{whichmail}"),
            SearchVerify.new(m, ["BODY", "counter #{whichmail}"], [whichmail]),
          ]
        end, 
        
        ZMVolumeHelper.genReset,  

        if(x == 'secondaryMessage')          
          v(ZMVolume.new('-ts')) do |mcaller, data|
            mcaller.pass = (data[0] == 0) && (data[1].include?("Turned off the current"))
          end
        end,       

        #Clean up action, leave comment for now, neeed to delete message as well              
        # Delete the new volume
        #v(ZMVolume.new('-d' ,'-id', cid)) do |mcaller, data|
        #  mcaller.pass = (data[0] == 0) && data[1].include?("Deleted volume #{cid}")
        #end,      
        # Clean up
        #StafSystem.new(Model::TARGETHOST, File.join('/bin','rm'), 'root', '-r','-f', mfilePath)
      ]    
    end     
  end,  
  
]

#
# Tear Down
#
current.teardown = [   
  p(m.method('logout')),
  p(m.method('disconnect')),        
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end