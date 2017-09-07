#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
#
# Very simple dumb fire imap mock server
require 'socket'
require 'ostruct'
require 'yaml'

configServer = OpenStruct.new
configServer.port = 7111
configServer.greeting = "* OK qa07.lab.zimbra.com Zimbra IMAP4rev1 service ready"

# Protocol definition " has to be escaped
pResponse = []
pResponse << { :match => /([^ ]*)? STARTTLS/i, :response => ['#{$1} BAD STARTTLS']}
pResponse << { :match => /([^ ]*)? CAPABILITY/i, :response => ['* CAPABILITY IMAP4rev1', '#{$1} OK CAPABILITY']}
pResponse << { :match => /([^ ]*)? SELECT INBOX/i, :response => ['* 0 EXISTS',
'* 0 RECENT',
'* OK [UIDVALIDITY 1] UIDs are valid for this mailbox',
'* OK [UIDNEXT 3] next expected UID is 3',
'* FLAGS (\Answered \Deleted \Draft \Flagged \Seen $Forwarded $MDNSent Forwarded $Junk $NotJunk Junk JunkRecorded NonJunk NotJunk)',
'* OK [PERMANENTFLAGS (\Answered \Deleted \Draft \Flagged \Seen $Forwarded $MDNSent Forwarded \*)] junk-related flags are not permanent',
'#{$1} [READ-WRITE] SELECT completed']}
pResponse << { :match => /([^ ]*)? SELECT/i, :response => '#{$1} OK select failure'}
pResponse << { :match => /([^ ]*)? STATUS INBOX/i, :response => ['* STATUS INBOX (UIDNEXT 3 UIDVALIDITY 1)', '#{$1} OK select failure']}
pResponse << { :match => /([^ ]*)? LIST/i,
  :response => [
    '* LIST (\Noselect) \"/\" \"INBOX\"',
    '#{$1} OK LIST completed'
  ]}
pResponse << { :match => /DIE/i, :die => true}
pResponse << { :match => /([^ ]*)? LOGOUT/i, :response => ['* BYE', '#{$1} OK see ya later'], :terminate => true}
pResponse << { :match => /([^ ]*?) .*/, :response => '#{$1} OK some junk'}


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
          begin
          outString = if(matchMe[:response].class == String)
            (eval '"' + matchMe[:response] + '"') + "\r\n"
          else
            matchMe[:response].inject('') do |carry, obj|
              evalResult = begin
                   eval '"' + obj + '"'
              rescue
                    ''
              end
              carry = carry + evalResult + "\r\n"
            end
          end 
        rescue => e
          puts e
        end
          puts "Sending #{mCounter}: #{outString}"
          begin 
            mySession.print outString
            mySession.flush
          rescue => e 
            puts e 
          end
        end
        break if matchMe[:terminate] == true
        exit if matchMe[:die] == true
      else
        puts "#{mCounter} no match"
      end 
    end
    mySession.close
  end
end



