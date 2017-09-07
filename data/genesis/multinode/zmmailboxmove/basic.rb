#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2006 Zimbra
#
# zmmailboxmove test

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
  require 'engine/simple'
  require 'data/multinode/setup'
  Engine::Simple.new(Model::TestCase.instance, false).run  
end 

require "model"
require "action/block"

require "action/mailboxmove" 
require "action/verify"
require "action/zmprov"
require "action/decorator"
require "action/zmmailbox"
require 'action/runcommand' 



require "net/imap"; require "action/imap" #Patch Net::IMAP library
require "net/pop" ; require 'action/pop'
require 'socket'


#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Zmmailboxmove basic"

name = 'zmmove'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
origHost = Model::TARGETHOST
destHost = Model::TARGETHOST.findService(:service)[-1]
memcachd = Model::TARGETHOST.findService(:memcached).first
proxy = (Model::TARGETHOST.findService(:imapproxy).first rescue origHost) || origHost
runThisTest = (origHost != destHost)
testAccount = origHost.cUser(name, Model::DEFAULTPASSWORD)
mimap = d
gid = d

class MCRequest
  attr :server, true

  def initialize(server)
    self.server = server
  end
  
  def send(request)
    memcache = TCPSocket::new(server, 11211)
    memcache.puts request
    hit = memcache.gets.chop
    unless(hit.include?('END'))
      hit = "%s %s"%[hit, memcache.gets.chop]
    end
    memcache.close
    hit
  end

end

memcache = MCRequest.new(memcachd.to_s)

include Action

#
# Setup
#
current.setup = [
                 
                ]

#
# Execution
#
if(runThisTest)
  current.action = [    
                    
                    # Create account
                    CreateAccount.new(testAccount.name, testAccount.password, 'zimbraMailHost', origHost.to_s),  
                    # Do a soap login, this will trigger memcache
                    ZMMail.new('-m', testAccount.name, '-p', testAccount.password, '-u', "http://%s"%proxy.to_s, 'gid'),
                    # Get GID
                    v(ZMProv.new('ga', testAccount.name, 'zimbraId')) do |mcaller, data |
                      gid = data[1][/zimbraId: (.*)$/, 1]
                      mcaller.pass = true
                    end,
                    # Add some data
                    cb("Add some data") do
                      mimap = Net::IMAP.new(proxy, *proxy.imap) 
                      mimap.login(testAccount.name, testAccount.password) 
                      mimap.append("INBOX", "test data")
                      mimap.logout
                      begin
                        pop = Net::POP3.new(proxy, *proxy.pop)
                        pop.tls = true
                        pop.start(testAccount.name, testAccount.password)
                        pop.each_mail do |m| 
                        end
                        pop.finish
                      rescue => e
                        puts e
                      end
                    end,
                    v(cb("Check result using imap select") do
                        mimap = Net::IMAP.new(origHost, *origHost.imap) 
                        mimap.login(testAccount.name, testAccount.password) 
                        mimap.select("INBOX")
                        result = mimap.fetch(1..1,'RFC822')
                        mimap.logout
                        result
                      end) do |mcaller, data|                      
                      mcaller.pass = data[0].attr['RFC822'].include?('test data')  rescue false
                    end,
                    # Move account to slave host
                    v(cb("Move account to slave host") do    
                        MailMove.new('-a', testAccount.name, '-s',  origHost.to_s, '-t',  destHost.to_s).run
                      end) do |mcaller, data|
                      mcaller.pass = data[0] == 0
                    end,
                    v(cb("Check to see if imap route is flushed") do
                        memcache.send("get route:proto=imap;user=%s"%testAccount.name)
                      end) do |mcaller, data|
                      mcaller.pass = ! data.include?(testAccount.name)
                    end,

                    v(cb("Check to see if pop3 route is flushed") do
                        memcache.send("get route:proto=pop3;user=%s"%testAccount.name)
                      end) do |mcaller, data|
                      mcaller.pass = ! data.include?(testAccount.name)
                    end,


                    v(cb("Check to see if http route is flushed") do                    
                        memcache.send("get route:proto=http;id=%s"%gid)
                      end) do |mcaller, data|
                      mcaller.pass = ! data.include?(gid.to_s)
                    end,
                    
                    v(RunCommand.new('zmproxypurge', 'zimbra', '-i', '-a', testAccount.name)) do |mcaller, data|
                      entries = data[1].split("\n").select { |x| !x.include?('null') } rescue []
                      mcaller.pass = entries.size == 0
                    end,

                    v(cb("Check result after move using imap select") do
                        mimap = Net::IMAP.new(destHost, *destHost.imap)
                        begin 
                          mimap.login(testAccount.name, testAccount.password) 
                          mimap.select("INBOX")
                          result = mimap.fetch(1..1,'RFC822')
                          mimap.logout
                          result
                        rescue => e       
                          e
                        end
                      end) do |mcaller, data|
                      mcaller.pass = data[0].attr['RFC822'].include?('test data') rescue false   
                    end 
                   ]
else
  current.action = []
end
#
# Tear Down
#
current.teardown = [        
                    
                   ]

if($0 == __FILE__)
  Engine::Simple.new(Model::TestCase.instance, false).run  
end
