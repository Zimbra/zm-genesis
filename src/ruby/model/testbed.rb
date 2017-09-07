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
#
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end

require 'model/env'
require 'model/user'

module Model # :nodoc
  require "socket"
  if Socket.gethostbyname(Socket.gethostname).first =~ /zimbra/
    TestDomain = Domain.new('eng.zimbra.com') unless defined?(TestDomain)  #domain name of our test bed
  else
    TestDomain = Domain.new('eng.vmware.com') unless defined?(TestDomain)  #domain name of our test bed
  end
  QA04 = Host.new('qa04', TestDomain) unless defined?(QA04) #primary test bed
  QA03 = Host.new('qa03', TestDomain) unless defined?(QA03) #secondar test bed
  IMAP = 143
  IMAPSSL = 993
  POP = 110
  POPSSL = 995
  PTMS = ENV['tms'] || 'zqa-tms.eng.vmware.com'

  
  DEFAULTPASSWORD = 'test123'
  unless defined?(HOSTINFORMATION)
    begin
      require 'xmlrpc/client'
      require 'yaml'
      require 'socket'
      hostArray = Socket.gethostbyname(Socket.gethostname)
      begin
        if(hostArray.first == 'localhost') #ipv6 bug.. or some machine stick fqdn as canical name for locahost
          hostArray = hostArray[1].select {|x| x.include?(TestDomain.name) }
        end
        if (hostArray[2] == Socket::AF_INET) # for now all ip6 are not to be used
          myIp = nil
          begin
            orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true  # turn off reverse DNS resolution temporarily
            UDPSocket.open do |s|
              s.connect '64.233.187.99', 1
              myIp = s.addr.last
            end
          ensure
            Socket.do_not_reverse_lookup = orig
          end
        end
        hostArray = hostArray.first.split('.', 2)
      rescue
        hostArray = ['localhost', 'eng.vmware.com']
        myIp = nil
      end
      lName = hostArray.join('.')
      lHost, lDomain = hostArray
      result =  {'target_machine' => lName, 'name' => lHost,  'domain' => lDomain, 'architecture' => 1}
      server = XMLRPC::Client.new2("http://%s/xmlrpc/api"%PTMS)
     
      callresult = YAML.load(server.call("machine.Gethostinformation", lHost, lDomain))
      result = callresult  if callresult.has_key?('name')
      HOSTINFORMATION = result
    rescue StandardError, Timeout::Error
      HOSTINFORMATION = result
    end
  end

  TARGETHOST = begin
                 myHost, myDomain = HOSTINFORMATION['target_machine'].split('.', 2) 
                 Host.new(myHost, Domain.new(myDomain))
               end unless defined?(TARGETHOST)
  
  TARGETHOST.architecture = begin
                              server = XMLRPC::Client.new2("http://%s/xmlrpc/api"%PTMS) 
                              result = YAML.load(server.call("machine.Gethostinformation", TARGETHOST.name, TARGETHOST.domain.name)) 
                              result['architecture_id']
                            rescue StandardError, Timeout::Error
                              24 #DEFAULT OS
                            end unless (TARGETHOST.architecture)
  TARGETHOST.ip = myIp
  
  SLAVEHOST = Host.new('qa15', TestDomain) unless defined?(SLAVEHOST) #Hard code to qa15 for now
  
  CLIENTHOST = begin
                 Host.new(HOSTINFORMATION['name'], Domain.new(HOSTINFORMATION['domain']))
               end unless defined?(CLIENTHOST) 
  
  YAHOOACCOUNTS = [ yahooAccount = Model::YahooImapUser.new("zimbraone@ymail.com", "test123") ]
  yahooAccount.host =  Model::Host.new('imap', 'mail.yahoo.com', false)
  DATAPATH = File.join('/opt', 'qa', 'genesis', 'data', 'TestMailRaw')


end

