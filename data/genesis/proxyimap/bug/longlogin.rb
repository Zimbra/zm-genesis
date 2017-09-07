#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# Bug #67020 IMAP Login with too long account results in Nginx internal server error response
#

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"

require "action/zmprov"
require "action/proxy"
require "action/sendmail"
require "action/verify"
require "net/imap"; require "action/imap" #Patch Net::IMAP library
require "net/pop"; require "action/pop"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Too long login names in IMAP and POP3"

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
name = "admin" if ($0 == __FILE__)
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

include Action
Net::IMAP.add_authenticator('PLAIN', PlainAuthenticator)

#Net::IMAP.debug = true
#
# Setup
#
current.setup = [
   
]

#
# Execution
#
current.action = [
  if Model::TARGETHOST.proxy
[
    [50, 254 - "@#{Model::TARGETHOST}".size, 257 - "@#{Model::TARGETHOST}".size, 500, 1000, 5000, 10000].map do |x|
      v(cb("Check alert") do
          mResult = Array.new
          mTemp = Net::IMAP.new(Model::TARGETHOST, *Model::TARGETHOST.imap)
          acc = Array.new(x) { (rand(122-97) + 97).chr }.join
          mLogin = mTemp.login( acc + "@#{Model::TARGETHOST}", testAccount.password) 
          mTemp.logout
          mTemp.disconnect 
          mResult = mLogin, mTemp
        end) do |mcaller, data|
        mcaller.pass = data.is_a?(Net::IMAP::NoResponseError) && data.message =~ /login failed/i
      end
    end,
    
    [50, 255 - "@#{Model::TARGETHOST}".size, 257 - "@#{Model::TARGETHOST}".size, 500, 1000, 5000, 10000].map do |x|
      v(cb("Check alert") do
          mResult = Array.new
          mTemp = Net::POP3.new(Model::TARGETHOST, *Model::TARGETHOST.pop)
          acc = Array.new(x) { (rand(122-97) + 97).chr }.join
          mLogin = mTemp.start( acc + "@#{Model::TARGETHOST}", testAccount.password) 
          mTemp.close
          mResult = mLogin, mTemp
        end) do |mcaller, data|
        mcaller.pass = data.is_a?(Net::POPAuthenticationError) && (data.message =~ /login failed/i ||
          data.message =~ /invalid username\/password/i)
      end
    end,

    [50, 254 - "@#{Model::TARGETHOST}".size, 257 - "@#{Model::TARGETHOST}".size, 500, 1000, 5000, 10000].map do |x|
      v(cb("Check alert") do
          mResult = Array.new
          mTemp = Net::IMAP.new(Model::TARGETHOST, *Model::TARGETHOST.imap)
          acc = Array.new(x) { (rand(122-97) + 97).chr }.join
          mLogin = mTemp.authenticate( 'PLAIN', '', acc + "@#{Model::TARGETHOST}", testAccount.password) 
          mTemp.logout
          mTemp.disconnect 
          mResult = mLogin, mTemp
        end) do |mcaller, data|
        mcaller.pass = data.is_a?(Net::IMAP::NoResponseError) && (data.message =~ /AUTHENTICATE failed/i ||
                                                                  data.message =~ /login failed/i)
      end
    end
    
    # action/AuthPlain is to be fixed to make it working
    #[50, 255 - "@#{Model::TARGETHOST}".size, 257 - "@#{Model::TARGETHOST}".size, 500, 1000, 5000, 10000].map do |x|
    #  v(cb("Check alert") do
    #      mResult = Array.new
    #      mTemp = Net::POP3::AuthPlain.new(Model::TARGETHOST, *Model::TARGETHOST.pop)
    #      acc = Array.new(x) { (rand(122-97) + 97).chr }.join
    #      mLogin = mTemp.start( acc + "@#{Model::TARGETHOST}", testAccount.password, '') 
    #      mTemp.close
    #      mResult = mLogin, mTemp
    #    end) do |mcaller, data|
    #    mcaller.pass = data.is_a?(Net::POPAuthenticationError) && (data.message.include?("login failed") ||
    #      data.message.include?("line is too long"))
    #  end
    #end,
    ]
  end
]

#
# Tear Down
#
current.teardown = [

]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end

