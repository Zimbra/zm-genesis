#!/usr/bin/ruby -w
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# IMAP catenate
# 

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
require "set"
require 'timeout'

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP Catenate test"

include Action 

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s 
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)
 
class ImapURL # :nodoc:
  def send_data(imap)
    imap.send(:send_url, @data) 
  end
  
  def validate
    # do nothing, return nil - for ruby 1.9 compliance
  end
  
  private
  
  def initialize(data)
    @data = data
  end
end
class CatenateImap < Net::IMAP
  def catenate(mailbox, messages, flags = nil, date_time = nil)
    args = []
    args.push(flags) if flags
    args.push(date_time) if date_time
    args.push('CATENATE')  
    begin
    if messages.class != Array
      messages = [messages]
    end
    
    mesString = messages.map do |x|
      if(x.include?('UID=') || x.include?('uid='))
        ['URL', ImapURL.new(x)]
      else
        ['TEXT', Literal.new(x)]
      end
    end.flatten
    rescue => e
      put e      
    end     
    args.push(mesString)   
    Timeout::timeout(10) {
      send_command("APPEND", mailbox, *args)
    }   
  end
  
  def send_literal_plus(str)
    put_string("{" + str.length.to_s + "+}"+CRLF)
    put_string(str)
  end
  
  def send_url(str)
    put_string('"'+str+'"')
  end 
  
 
end


#mimap = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)
mimap = CatenateImap.new(Model::TARGETHOST, Model::IMAPSSL, true)


 
#
# Setup
#
current.setup = [
   
]
message = <<EOF.gsub(/\n/, "\r\n").gsub(/REPLACEME/, testAccount.name)
Subject: hello
From: genesis@test.org
To: REPLACEME

hello world
EOF

#
# Execution
#
current.action = [  
  CreateAccount.new(testAccount.name,testAccount.password),
   cb("Send an email") {
    SendMail.new(testAccount.name,message).run
  }, 
  
 
  p(mimap.method('login'),testAccount.name,testAccount.password),
  
  # Simple append command
  p(mimap.method('create'),"INBOX/append"),
  
  # Catenate with URL
  p(mimap.method('create'),"INBOX/original"),
  p(mimap.method('create'),"INBOX/catenate"),
  
  # Append with text message and bad url
  v(p(mimap.method('catenate'),"INBOX/catenate",[message,"/Inbox/;UID=297/;Section=2"]), &IMAP.noResponseError('URL')),
  
  # Append with some valid url
  p(mimap.method('catenate'), "INBOX/original",message),
  p(mimap.method('select'),"INBOX/original"),
  v(p(mimap.method('fetch'),1..1, 'UID')) do |mcaller, data|
    uid = data[0].attr['UID']   
    response = mimap.catenate("INBOX/catenate",["/INBOX/original/;UID=#{uid}"])     
    mimap.select("INBOX/catenate")
    response2 = mimap.fetch(1..1,'RFC822.TEXT')
    mcaller.pass = (response.class == Net::IMAP::TaggedResponse) && response.raw_data.include?('completed') &&
      response2[0].attr['RFC822.TEXT'].include?('hello world')
  end,   
  
  # Multi segment
  p(mimap.method('select'),"INBOX/original"),
  v(p(mimap.method('fetch'),1..1, 'UID')) do |mcaller, data|
    uid = data[0].attr['UID']   
    response = mimap.catenate("INBOX/catenate",["/INBOX/original/;UID=#{uid}","whatever"])   
    mimap.select("INBOX/catenate")  
    response2 = mimap.fetch(2..2,'RFC822.TEXT')    
    mcaller.pass = (response.class == Net::IMAP::TaggedResponse) && response.raw_data.include?('completed') &&
      response2[0].attr['RFC822.TEXT'].include?('whatever')
  end,   
  
  p(mimap.method('delete'), "INBOX/original"),
  p(mimap.method('delete'), "INBOX/catenate"),
  v(
    p(mimap.method('catenate'),"INBOX/append", message, [:Answered, :Deleted, :Draft, :Flagged, :Seen], Time.at(945702800))
  ) { |caller, data|
    caller.pass = (data.class == Net::IMAP::TaggedResponse) && 
      (data.name == "OK")       
  },
  
  p(mimap.method('select'),"INBOX/append"),
  v(
    p(mimap.method('fetch'), 1, "ALL")
  ){ |caller, data| 
  
    caller.pass = (data[0].class == Net::IMAP::FetchData) &&
      (data[0].attr['ENVELOPE'].subject == 'hello') &&
      (data[0].attr['FLAGS'].to_set == (Set.new [:Deleted, :Draft, :Flagged, :Answered, :Seen, :Recent])) &&
      (data[0].attr['ENVELOPE'].from[0].mailbox == 'genesis') &&
      (data[0].attr['ENVELOPE'].from[0].host == 'test.org') &&
      (data[0].attr['ENVELOPE'].sender[0].mailbox == 'genesis') &&
      (data[0].attr['ENVELOPE'].sender[0].host == 'test.org') 
  },
  
  p(mimap.method('catenate'),"INBOX/append", message, ['JUNK'], Time.at(945702800)),     
  AppendVerify.new(2, ['Junk', '$Junk', :Recent], Time.at(945702800),mimap),
    
  p(mimap.method('catenate'),"INBOX/append", message, ['JUNKRECORDED'], Time.at(945702800)),      
  AppendVerify.new(3, ['JunkRecorded', :Recent], Time.at(945702800),mimap),
    
  p(mimap.method('catenate'),"INBOX/append", message, ['NONJUNK'], Time.at(945702800)),     
  AppendVerify.new(4, ['$NotJunk','NotJunk','NonJunk', :Recent], Time.at(945702800), mimap),
  
  p(mimap.method('catenate'),"INBOX/append", message, ['NOTJUNK'], Time.at(945702800)),     
  AppendVerify.new(5, ['$NotJunk','NotJunk','NonJunk', :Recent], Time.at(945702800),mimap),
  
  p(mimap.method('catenate'),"INBOX/append", message, ['$FORWARDED'], Time.at(945702800)),     
  AppendVerify.new(6, ['$Forwarded','Forwarded', :Recent],  Time.at(945702800),mimap),
  
  p(mimap.method('catenate'),"INBOX/append", message, ['NIL'], Time.at(945702800)),      
  AppendVerify.new(7, [:Recent, 'NIL'], Time.at(945702800),mimap),
  
  #p(mimap.method('catenate'),"INBOX/append", message, [:Recent], Time.at(945702800)),   
  #p(mimap.method('fetch'), 8, "ALL"), 
  p(mimap.method('delete'), "INBOX/append"),
  v(
    p(mimap.method('catenate'),"INBOX/append/hmm", message, [:Seen], Time.now)
  ) { |caller, data|
    caller.pass = (data.class == Net::IMAP::NoResponseError) &&
      data.message.include?('no such mailbox') 
  },
  
  p(mimap.method('create'),"INBOX/appendbad"),  
   
  v(
    p(mimap.method('catenate'),"Contacts", message, [:Seen], Time.at(945702800))
  ) { |caller, data|
    caller.pass = (data.class == Net::IMAP::NoResponseError) &&
      data.message.include?('failed') 
  },
  
  v(
    p(mimap.method('catenate'),"Junk", message, [:Seen], Time.at(945702800))
  ) { |caller, data|
      caller.pass = (data.class == Net::IMAP::TaggedResponse)  
  },
  
  v(
    p(mimap.method('catenate'),"Trash", message, [:Seen], Time.at(945702800))
  ) { |caller, data|
      caller.pass = (data.class == Net::IMAP::TaggedResponse)  
  },
  
  v(
    p(mimap.method('catenate'),"INBOX/appendbad", message, ["not/allowed"], Time.at(945702800))
  ) { |caller, data|
       caller.pass = (data.class == Net::IMAP::TaggedResponse)  
  },
  
  #empty flag
  p(mimap.method('catenate'),"INBOX/appendbad", message, [], Time.now),  
  
   
   
  p(mimap.method('select'), "INBOX/appendbad"),
  p(mimap.method('fetch'),1..20, 'ALL'),
  p(mimap.method('delete'), "INBOX/appendbad"),
  p(mimap.method('logout')),
  
  
]

#
# Tear Down
#
current.teardown = [      
  p(mimap.method('disconnect')),  
  DeleteAccount.new(testAccount.name),
  Clean.new(File.join(Command::ZIMBRAPATH,"store", "incoming")),
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end 