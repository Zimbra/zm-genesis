#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
#
# Very simple dumb fire pop mock server
require 'socket'
require 'ostruct'
require 'yaml'

configServer = OpenStruct.new
configServer.port = 7110
configServer.greeting = "+OK POP3 server ready"

# Protocol definition
pResponse = []
pResponse << { :match => /CAPA|STLS/i, :response => '-ERR unknown command'}
pResponse << { :match => /DIE/i, :die => true}
pResponse << { :match => /QUIT/i, :response => '+OK', :terminate => true}
pResponse << { :match => /STAT/i, :response =>  '+OK 2 320'}
pResponse << { :match => /LIST/i, :response =>  ['+OK 2 messages (320 octets)', '1 120','2 200', '.']}
pResponse << { :match => /UIDL/i, :response =>  ['+OK 2 messages', '1 257.tvzCrqXw,2kJfCJN8zPumuAxs+Q=','2 256.tvzCrqXw,2kJfCJN8zPumuAxs+Q=', '.']}
pResponse << { :match => /RETR|TOP/i, :response =>  '-ERR some junk'}
pResponse << { :match => /.*/, :response => '+OK some junk'}

puts "System Configuration"
puts YAML.dump(configServer)
puts "Response Matrix"
puts YAML.dump(pResponse)

server = TCPServer.new(configServer.port)

#Main server loop
counter = 0
while(session = server.accept)
  counter = counter + 1
  Thread.new(session) do |mySession|
    #Say Hello 
    mySession.print configServer.greeting + "\r\n"
    mySession.flush
    
    #Localized counter
    mCounter = counter
    
    while(true)
      #Main Loop 
      request = mySession.gets
      if(request.nil?)
        puts "Connection ends #{mCounter}"
        break
      end
      puts "Getting #{mCounter}: #{request}"
      matchMe = pResponse.find do |thisOne|
        request =~ thisOne[:match]
      end
      if(matchMe)
        if(matchMe[:response])
          outString = if(matchMe[:response].class == String)
            matchMe[:response]
          else
            matchMe[:response].join("\r\n")
          end
          puts "Sending #{mCounter}: #{outString}"
          begin 
            mySession.print outString + "\r\n"
            mySession.flush
          rescue => e 
            puts e 
          end
        end
        break if matchMe[:terminate] == true
        exit if matchMe[:die] == true
      end 
    end
    mySession.close
  end
end



