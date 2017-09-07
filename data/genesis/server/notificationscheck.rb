#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2012 VMWare
#
# check for unique zimbraId

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

mypath = 'data'
if($0 =~ /data\/genesis/)
  mypath += '/genesis'
end

require "model"
require "action/block"
require "action/verify"
require "#{mypath}/install/utils"
require "action/zmsoap"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "admin notifications test"


include Action

mSubject = "Service * started"
mId = nil

#
# Setup
#
current.setup = [

]

#
# Execution
#
current.action = [
  
  v(cb("retrieve messages") do
    mResult = ZMSoapXml.new('-m', 'admin', '-p', Model::DEFAULTPASSWORD, "SearchRequest/@types=message", "query=subject:\"#{mSubject}\"").run
  mId = mResult[1].elements['SearchResponse'].elements['m'].attributes['id'] rescue nil
    mResult.push(mId)
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !mId.nil?
  end,
  
  v(cb("get raw message") do
    mResult = ZMSoapXml.new('-m', 'admin', '-p', Model::DEFAULTPASSWORD, "GetMsgRequest/m", "@id=#{mId}", "@raw=1").run
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].nil? &&
                   !(content = data[1].elements['GetMsgResponse'].elements['m/content']).nil? &&
                   content.text =~ /Return-Path: admin@#{Utils::zimbraDefaultDomain}\s+/
  end,

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
