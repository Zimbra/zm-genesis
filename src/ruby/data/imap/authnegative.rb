#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
#
# IMAP authentication negative test cases
# 

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"
require "action/block"
require "action/decorator"
require "action/zmprov"
require "action/proxy"
require "action/verify"
require "net/imap"; require "action/imap" #Patch Net::IMAP library
require "timeout"

include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP Auth Negative Test"

mimap = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)
#
# Setup
#
current.setup = [
 
]

#
# Execution
#
current.action = [
  # the following sequence of 3 verifications is in accordance with bug #56018
  # please keep the sequence
  v( #Non existing auth mechanism
    proxy(mimap.method('send_command'),'AUTHENTICATE FOO')
  ) { |caller, data| 
    caller.pass = (data.class == Net::IMAP::NoResponseError) && 
      (data.message.include?("not supported"))         
  },  
  v( #Missing Argument
    proxy(mimap.method('send_command'),'AUTHENTICATE')
  ) { |caller, data| 
    caller.pass = (data.class == Net::IMAP::BadResponseError) && 
      (data.message.include?(Action::IMAP.badString))         
  },
  v( #Missing Argument plus space
    proxy(mimap.method('send_command'),'AUTHENTICATE ')
  ) { |caller, data| 
    caller.pass = (data.class == Net::IMAP::BadResponseError) && 
      (data.message.include?(Action::IMAP.badString))       
  },  
                  
  v(cb("Negative Test on Timer, large password", 120) do          
        response = nil 
        mimap2 = nil
        begin
          mimap2 = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)
          timeout(100) {           
            mimap2.method('send_command').call("LOGIN foo #{'hi'*10000000}") { |data|           
                response = data 
            }           
          }  
        rescue => e
        ensure
          unless mimap2.nil?
            mimap2.logout
            mimap2.disconnect
          end
        end  
        response
    end
  ) do |mcaller, data|
    mcaller.pass = (data.class == OpenSSL::SSL::SSLError ||
                    data.class == Errno::EPIPE ||
                    (data.class == Net::IMAP::TaggedResponse && data.name == 'BAD'))
    end,
  
  proxy(Kernel.method('sleep'),5),
  
]

#
# Tear Down
#
current.teardown = [         
  proxy(mimap.method('logout')),
  proxy(mimap.method('disconnect'))
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end 
