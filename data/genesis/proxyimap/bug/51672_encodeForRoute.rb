#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2011 Zimbra
# Encoding user name for Route Lookup
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
current.description = "Username / password encoding for Route Lookup"

# name and pass include all the allowed char classes to test the encoding
name = '!%a|{E-Q}$.x&j.^i_L#l~3+*=z?'+Time.now.to_i.to_s 
name_escaped = name.gsub(/&/, "\\\\&")
name_escaped.gsub!(/\|/, "\\\\|")
name_escaped.gsub!(/\$/, "\\\\$")

pass = '!%a|{E-Q}$.x&j.^i_L#l(~)3+*=z?'
pass_escaped = pass.gsub(/&/, "\\\\&")
pass_escaped.gsub!(/\|/, "\\\\|")
pass_escaped.gsub!(/\$/, "\\\\$")
pass_escaped.gsub!(/\)/, "\\\\)")
pass_escaped.gsub!(/\(/, "\\\\(")

testAccount = Model::TARGETHOST.cUser(name, pass)

mimap = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)
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
  
  # create account
  v(ZMProv.new('ca', name_escaped + '@' + Model::TARGETHOST, pass_escaped)) do |mcaller, data|
    mcaller.pass = (data[0] == 0)
  end, 
  
  # IMAP login and operation verification
  LoginVerify.new(mimap, testAccount.name,testAccount.password),
  
  p(mimap.method('select'),'INBOX'),
  cb("Create 20 messages") {     
    0.upto(2) { |i|                
      cflags = [flags[(i+4)%flags.size]]
      mimap.append("INBOX",message.gsub(/REPLACEME/,i.to_s),cflags, Time.now)    
      "Done"
    }
  },
   
  #POP login and operation verification
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
  
  # add kerberos test
  
  p(mimap.method('logout')),  
]

#
# Tear Down
#
current.teardown = [     
  proxy(mimap.method('disconnect')),
  DeleteAccount.new(name_escaped + '@' + Model::TARGETHOST)
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end

