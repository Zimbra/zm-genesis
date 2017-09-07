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
# zmsoap for sending and getting email with various options
#

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "action/command"
require "action/zmprov"
require "action/verify"
require "action/zmsoap"
require "model"


include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "zmsoap mail requests"

timeNow = Time.now.to_i.to_s
prefix = File.expand_path(__FILE__).sub(/.*?(data\/)(genesis\/)?(zm)?/, 'zm').sub('.rb', '').gsub(/\/|\(|\)/, '')
domain = Model::Domain.new("#{prefix}dom#{timeNow}.com")
testAccount1 = domain.cUser(prefix + 'acct1' + timeNow)
testAccount2 = domain.cUser(prefix + 'acct2' + timeNow)
subject1 = prefix + "subject" + timeNow
content1 = prefix + "content" + timeNow
mId = ""
sentId = ""
inboxId = ""
#
# Setup
#

current.setup = [

]
#
# Execution
#
current.action = [

  ZMProv.new('cd', domain.name),

  ZMProv.new('ca', testAccount1.name, Model::DEFAULTPASSWORD),

  ZMProv.new('ca', testAccount2.name, Model::DEFAULTPASSWORD),

  cb("Get Sent folder ID") do
    mResult = ZMSoapXml.new('-m', testAccount1.name, '-p', Model::DEFAULTPASSWORD, "GetFolderRequest/folder/@path=Sent").run
    next mResult if mResult[0] != 0
    sentId = (mResult[1].elements['GetFolderResponse'].get_elements('folder')).first.attributes['id']
  end,

  cb("Get Inbox folder ID") do
    mResult = ZMSoapXml.new('-m', testAccount1.name, '-p', Model::DEFAULTPASSWORD, "GetFolderRequest/folder/@path=Inbox").run
    next mResult if mResult[0] != 0
    inboxId = (mResult[1].elements['GetFolderResponse'].get_elements('folder')).first.attributes['id']
  end,

  v(cb("Send an email and verify that sent the email is in Sent folder") do
    mResult = ZMSoapXml.new('-m', testAccount1.name, '-p', Model::DEFAULTPASSWORD, "SendMsgRequest/m",
                            "e @a=#{testAccount2.name} @t=t",
                            "../su=#{subject1}",
                            "../mp @ct=\"text\/plain\" content=#{content1}").run
    next mResult if mResult[0] != 0
    mId = (mResult[1].elements['SendMsgResponse'].get_elements('m')).first.attributes['id']
    mResult = ZMSoapXml.new('-m', testAccount1.name, '-p', Model::DEFAULTPASSWORD, "GetMsgRequest/m", "@id=#{mId}").run
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].nil? &&
                   data[1].elements['GetMsgResponse'].elements['m/su'].text == subject1 &&
                   data[1].elements['GetMsgResponse'].elements['m/fr'].text == content1 &&
                   (idDetails = data[1].elements['GetMsgResponse'].get_elements('m')).first.attributes['id'] == mId &&
                   idDetails.first.attributes['l'] == sentId &&
                   (headerDetails = data[1].elements['GetMsgResponse'].get_elements('m/e')).size == 2 &&
                   headerDetails.collect{|h| [h.attributes['t'], h.attributes['a']]}.sort == [['f', testAccount1.name],
                                                                                              ['t', testAccount2.name]].sort
  end,

  WaitQueue.new,

  v(cb("Verify the email is present in recipients mailbox") do
    ZMSoapXml.new('-m', testAccount2.name, '-p', Model::DEFAULTPASSWORD, "SearchRequest/@types=message", "query=subject:#{subject1}").run
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].nil? &&
                   data[1].elements['SearchResponse'].elements['m/su'].text == subject1 &&
                   data[1].elements['SearchResponse'].elements['m/fr'].text == content1 &&
                   (idDetails = data[1].elements['SearchResponse'].get_elements('m')).first.attributes['l'] == inboxId &&
                   !(mId = idDetails.first.attributes['id']).nil?
  end,

  v(cb("Mark the email as read") do
    ZMSoapXml.new('-m', testAccount2.name, '-p', Model::DEFAULTPASSWORD, "MsgActionRequest/action @id=#{mId} @op=read").run
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].nil? &&
                   data[1].elements['MsgActionResponse'].elements['action'].attributes['id'] == mId &&
                   data[1].elements['MsgActionResponse'].elements['action'].attributes['op'] == "read"
  end,

  v(cb("Delete the email from mailbox") do
    ZMSoapXml.new('-m', testAccount2.name, '-p', Model::DEFAULTPASSWORD, "MsgActionRequest/action @id=#{mId} @op=delete").run
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].nil? &&
                   data[1].elements['MsgActionResponse'].elements['action'].attributes['id'] == mId &&
                   data[1].elements['MsgActionResponse'].elements['action'].attributes['op'] == "delete"
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
