#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2011 Zimbra
#
# Wrapper for wget calls
#

if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
  $: << './'
end

require 'openssl'
require 'base64'
require 'model/testbed'
require 'action/zmprov'
 
 
module Action # :nodoc

  # following methods require arbitrary URL
  def genHttpCheck(urlString)
    cb("Check URL: %s"%urlString) do
      RunCommand.new("wget", "root", "--no-proxy", '-P', '/tmp' ,'--no-check-certificate', '"' + 
                     urlString + '"').run.collect {|w| w.instance_of?(String)? w.encode('US-ASCII', 'UTF-8', {:invalid => :replace, :undef => :replace, :replace => ''}) : w}
    end
  end
  
  def verifyWget(urlString)
     v(genHttpCheck(urlString)) do |mcaller, data|
      mcaller.pass = (data[0] == 0) && data[1].include?("200 OK")
    end
  end
  
  def verifyWgetError(urlString)
     v(genHttpCheck(urlString)) do |mcaller, data|
      mcaller.pass = (data[0] != 0)
    end
  end
  
  # returns string value of mail mode on front end server - proxy or jetty
  def getFrontWebProtocol
    proto = 'http'
    mResponse = ''
    if Model::Servers.hasProxy?
      mResponse = ZMProv.new("gs #{Model::Servers.getServersRunning('proxy').first} zimbraReverseProxyMailMode").run[1]
    else
      mResponse = ZMProv.new("gs #{Model::Servers.getServersRunning('mailbox').first} zimbraMailMode").run[1]
    end
    proto = mResponse.split("\n")[1].match(/\S+$/)[0]
    return proto
  end

end

if $0 == __FILE__
  require 'test/unit'
  module Action

    # Unit test cases for wget wrapper TBD
  end
end

