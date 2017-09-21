if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"

require "action/zmprov"
require "action/proxy"
require "action/verify"
require "net/imap"; require "action/imap" #Patch Net::IMAP library

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "NGINX log watch test ZCS-2971"

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

mimap = Net::IMAP.new(Model::TARGETHOST, *Model::TARGETHOST.imap) 

include Action

#Net::IMAP.debug = true
#
# Setup
#
current.setup = [
   CreateAccount.new(testAccount.name,testAccount.password),
]

#
# Execution
#
current.action = [  
   	
	proxy(mimap.method('login'),testAccount.name,testAccount.password), 

  	v(ZMProv.new('gcf', 'zimbraReverseProxyUpstreamImapServers')) do |mcaller, data|
    	$imapserver = data[1]
    	mcaller.pass = data[0] == 0
    end,
  	
    v(RunCommand.new('tail', 'root', '-n2', File.join(Command::ZIMBRAPATH, 'log', 'nginx.log'))) do | mcaller, data |
  		if $imapserver == '' #if null then request should go to the local IMAP server else the remote one
  			mcaller.pass = data[1].include?(':7993')
  		else
  			mcaller.pass = data[1].include?(':8993')
  		end
 	 end
   	
]

#
# Tear Down
#
current.teardown = [
  proxy(mimap.method('logout')),  
  DeleteAccount.new(testAccount.name)
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end
