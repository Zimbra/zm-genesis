#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2006 Zimbra
# POP Basic test
# 
if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 

mypath = 'data'
if($0 =~ /data\/genesis/)
  mypath += '/genesis'
end

require "model"
require "action/block"
require "action/zmprov"
require "action/proxy" 
require "action/verify"
require "net/imap"; require "action/imap" #Patch Net::IMAP library
require "net/pop"
require "#{mypath}/install/configparser"
require "action/zmamavisd"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "POP Basic test"

name = 'pop'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s 
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

mimap = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)
pop = Net::POP3.new(Model::TARGETHOST, *Model::TARGETHOST.pop)
(mCfg = ConfigParser.new).run

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
  if !mCfg.getServersRunning('proxy').empty?
  [
    ZMProv.new('mcf', 'zimbraReverseProxyAuthWaitInterval', '0s'),
    v(cb("non existing account login") do
      mStart = DateTime.now
      Kernel.sleep(1)
      p(mimap.method('login'),testAccount.name,testAccount.password).run
      mResult = RunCommand.new('tail', Command::ZIMBRAUSER, '-100', File.join(Command::ZIMBRAPATH, 'log', 'nginx.log')).run
      mResult.push(mStart)
    end) do |mcaller, data|
      mcaller.pass = data[0] == 0 &&
                     ((mTime = data[1].split(/\n/).select {|w| w =~ /exited on signal 6/}).empty? ||
                     DateTime.parse(mTime.last[/^(.*\d+(:\d+){2})/, 1] + " " + data.last.zone) < data.last)
    end,
    ZMProv.new('mcf', 'zimbraReverseProxyAuthWaitInterval', '10s'),
#    ZMNginxctl.new('restart')
  ]
  end,

  CreateAccount.new(testAccount.name,testAccount.password),
  p(mimap.method('login'),testAccount.name,testAccount.password),
  #clean up
  p(mimap.method('select'),'INBOX'),
#  p(mimap.method('store'), 1..1000, "FLAGS", [:DELETED]),
#  p(mimap.method('close')),   
  cb("Create 20 messages") {     
    0.upto(2) { |i|                
      cflags = [flags[(i+4)%flags.size]]
      mimap.append("INBOX",message.gsub(/REPLACEME/,i.to_s),cflags, Time.now)    
      "Done"
    }
  },
   
  #pop action
  v(cb("Simple 20 mails fetch") {
    response = []   
    pop.start(testAccount.name, testAccount.password)
     
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
  p(mimap.method('select'),'INBOX'),
  p(mimap.method('store'), (1..-1), "FLAGS", [:DELETED]),
  p(mimap.method('close')),   
  
  # empty mailbox fetch
  v(cb("Simple 20 mails fetch") {
    response = ["Success"]  
    exitstatus = 0
    pop.finish 
    pop.start(testAccount.name, testAccount.password)
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