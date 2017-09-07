#!/usr/bin/ruby
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2006 Zimbra
#
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


#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP Literalplus test"

name = 'iext'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

mimap = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true) 
mimap2 = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true) 
mimap3 = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true) 

include Action

 
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
  v(cb("Literal Plus Login") { 
    length = testAccount.name.size
    lengthone = testAccount.password.size
    result = []
    begin
      mimap.method('send_command').call("login {#{length}+}\r\n#{testAccount.name} {#{lengthone}+}\r\n#{testAccount.password}")
      result[0] = mimap.responses
    rescue => e
      result[0] = e 
    end
    
    begin
      mimap2.method('send_command').call("login {#{length*10000}+}\r\n#{testAccount.name*10000} {#{lengthone}+}\r\n#{testAccount.password}")
      result[1] = mimap2.responses 
    rescue => e
      result[1] = e
    end
    result
  }) do |mcaller, data|   
     mcaller.pass = (data[0].class == Hash) &&
        ((Errno::EPIPE  === data[1]) || (Errno::ECONNRESET === data[1]) ||
        data[1].is_a?(Net::IMAP::BadResponseError) || data[1].is_a?(Net::IMAP::NoResponseError))               
  end,
  
  v(cb("Literal Plus Negative") do 
      result =  begin
        mimap3.method('send_command').call("login {-23+}\r\n#{testAccount.name} {-40}}\r\n#{testAccount.password}")
      rescue => e
        e
      end 
      result
  end) { |mcaller, data| mcaller.pass = data.is_a?(Net::IMAP::BadResponseError) }

]

#
# Tear Down
#
current.teardown = [
                    proxy(mimap.method('logout')),
                    proxy(mimap.method('disconnect')),
                    proxy(mimap2.method('logout')),
                    proxy(mimap2.method('disconnect')),
                    proxy(mimap3.method('logout')),
                    proxy(mimap3.method('disconnect')),
                    
                    DeleteAccount.new(testAccount.name),
]

if($0 == __FILE__)
  require 'engine/simple' 
  
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run    
end
