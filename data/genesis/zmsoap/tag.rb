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
# zmsoap for tag related operations
#

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "action/command"
require "action/zmprov"
require "action/verify"
require "action/zmsoap"
require "model"
require 'json'


include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "zmsoap tag requests"

timeNow = Time.now.to_i.to_s
prefix = File.expand_path(__FILE__).sub(/.*?(data\/)(genesis\/)?(zm)?/, 'zm').sub('.rb', '').gsub(/\/|\(|\)/, '')
domain = Model::Domain.new("#{prefix}dom#{timeNow}.com")
testAccount1 = domain.cUser(prefix + 'acct1' + timeNow)
testAccount2 = domain.cUser(prefix + 'acct2' + timeNow)
subject1 = prefix + "subject" + timeNow
content1 = prefix + "content" + timeNow
mId = ""
contactFirstName = 'firstname'+Time.now.to_i.to_s
contactLastName = 'lastname'+Time.now.to_i.to_s
contactEmail = 'email'+Time.now.to_i.to_s+'domain.com'
cId = ""
tId = ""
tasksId = ""
calItemId = ""
tagname1 = prefix + "tagname1" + timeNow
tagname2 = prefix + "tagname2" + timeNow
tagId = ""
tagColor = "4"
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

  v(cb("Create a tag") do
    ZMSoapXml.new('-m', testAccount1.name, '-p', Model::DEFAULTPASSWORD, "CreateTagRequest/tag @name=#{tagname1} @color=#{tagColor}").run
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].nil? &&
                   !(tagId = data[1].elements['CreateTagResponse'].elements['tag'].attributes['id']).nil? &&
                   data[1].elements['CreateTagResponse'].elements['tag'].attributes['name'] == tagname1 &&
                   data[1].elements['CreateTagResponse'].elements['tag'].attributes['color'] == tagColor
  end,

  cb("Send an email") do
    mResult = ZMSoapXml.new('-m', testAccount1.name, '-p', Model::DEFAULTPASSWORD, "SendMsgRequest/m",
                            "e @a=#{testAccount2.name} @t=t",
                            "../su=#{subject1}",
                            "../mp @ct=\"text\/plain\" content=#{content1}").run
    next mResult if mResult[0] != 0
    mId = (mResult[1].elements['SendMsgResponse'].get_elements('m')).first.attributes['id']
  end,

  WaitQueue.new,

  v(cb("Tag existing mail") do
    mResult = ZMSoapXml.new('-m', testAccount1.name, '-p', Model::DEFAULTPASSWORD, "MsgActionRequest/action @id=#{mId} @tag=#{tagId} @op=tag").run
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].nil? &&
                   data[1].elements['MsgActionResponse'].elements['action'].attributes['id'] == mId &&
                   data[1].elements['MsgActionResponse'].elements['action'].attributes['op'] == "tag"
  end,

  v(cb("Ensure that mail is tagged correctly") do
    mResult = ZMSoapXml.new('-m', testAccount1.name, '-p', Model::DEFAULTPASSWORD, "GetMsgRequest/m @id=#{mId}").run
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].nil? &&
                   data[1].elements['GetMsgResponse'].elements['m'].attributes['id'] == mId &&
                   data[1].elements['GetMsgResponse'].elements['m'].attributes['t'] == tagId
  end,

  v(ZMSoapXml.new('-m', testAccount1.name, '-p', Model::DEFAULTPASSWORD, "CreateContactRequest/cn",
                  "a=#{contactFirstName} @n=firstname",
                  "../a=#{contactLastName} @n=lastname",
                  "../a=#{contactEmail} @n=email")) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].nil? &&
                  (details = data[1].elements['CreateContactResponse'].get_elements('cn/a')).size == 3 &&
                  !(cId = data[1].elements['CreateContactResponse'].elements['cn'].attributes['id']).nil? &&
                  details.collect{|a| [a.attributes['n'], a.text]}.sort == [['email', contactEmail],
                                                                            ['lastname', contactLastName],
                                                                            ['firstname', contactFirstName],
                                                                           ].sort
  end,

  v(cb("Tag previously created contact") do
    mResult = ZMSoapXml.new('-m', testAccount1.name, '-p', Model::DEFAULTPASSWORD, "ContactActionRequest/action @id=#{cId} @tag=#{tagId} @op=tag").run
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].nil? &&
                   data[1].elements['ContactActionResponse'].elements['action'].attributes['id'] == cId &&
                   data[1].elements['ContactActionResponse'].elements['action'].attributes['op'] == "tag"
  end,

  v(cb("Ensure that contact is tagged correctly") do
    mResult = ZMSoapXml.new('-m', testAccount1.name, '-p', Model::DEFAULTPASSWORD, "GetContactsRequest/cn @id=#{cId}").run
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].nil? &&
                   data[1].elements['GetContactsResponse'].elements['cn'].attributes['id'] == cId &&
                   data[1].elements['GetContactsResponse'].elements['cn'].attributes['tn'] == tagname1
  end,

  cb("Get Task folder ID") do
    mResult = ZMSoapXml.new('-m', testAccount1.name, '-p', Model::DEFAULTPASSWORD, "GetFolderRequest/folder/@path=Tasks").run
    next mResult if mResult[0] != 0
    tasksId = (mResult[1].elements['GetFolderResponse'].get_elements('folder')).first.attributes['id']
  end,

  cb("Create a Task") do
    mResult = ZMSoapXml.new('-m', testAccount1.name, '-p', Model::DEFAULTPASSWORD, "CreateTaskRequest/m l=#{tasksId}",
                            "../inv/comp @priority=5 @name=#{subject1}",
                            "../../su=#{subject1}",
                            "../../mp @ct=\"text\/plain\" content=#{content1}").run
    next mResult if mResult[0] != 0
    tId = mResult[1].elements['CreateTaskResponse'].attributes['invId']
    calItemId = mResult[1].elements['CreateTaskResponse'].attributes['calItemId']
  end,

  v(cb("Tag previously created task") do
    ZMSoapXml.new('-m', testAccount1.name, '-p', Model::DEFAULTPASSWORD, "ItemActionRequest/action @id=#{calItemId} @tag=#{tagId} @op=tag").run
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].nil? &&
                   data[1].elements['ItemActionResponse'].elements['action'].attributes['id'] == calItemId &&
                   data[1].elements['ItemActionResponse'].elements['action'].attributes['op'] == "tag"
  end,

  v(cb("Ensure that task is tagged correctly") do
    ZMSoapXml.new('-m', testAccount1.name, '-p', Model::DEFAULTPASSWORD, "GetTaskRequest @id=#{calItemId}").run
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].nil? &&
                   data[1].elements['GetTaskResponse'].elements['task'].attributes['id'] == calItemId &&
                   data[1].elements['GetTaskResponse'].elements['task'].attributes['t'] == tagId
  end,

  v(cb("Modify created tag") do
    ZMSoapXml.new('-m', testAccount1.name, '-p', Model::DEFAULTPASSWORD, "TagActionRequest/action @op=rename @name=#{tagname2} @id=#{tagId}").run
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].nil? &&
                   data[1].elements['TagActionResponse'].elements['action'].attributes['id'] == tagId &&
                   data[1].elements['TagActionResponse'].elements['action'].attributes['op'] == "rename"
  end,

  v(cb("Delete created tag") do
    ZMSoapXml.new('-m', testAccount1.name, '-p', Model::DEFAULTPASSWORD, "TagActionRequest/action @op=delete @id=#{tagId}").run
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].nil? &&
                   data[1].elements['TagActionResponse'].elements['action'].attributes['id'] == tagId &&
                   data[1].elements['TagActionResponse'].elements['action'].attributes['op'] == "delete"
  end,
    
  RunCommand.new('/bin/echo', 'root',
                 "\"{\\\"CreateTagRequest\\\":{\\\"_jsns\\\":\\\"urn:zimbraMail\\\"," +
                 "\\\"tag\\\":{\\\"name\\\":\\\"#{tagname1}\\\", \\\"color\\\":\\\"#{tagColor}\\\"}}}\"",
                 '>','/tmp/jsonfile'),
    
  v(cb("Create tag") do
    ZMSoap.new('-m', testAccount1.name, '-p', Model::DEFAULTPASSWORD, '--json', '-f', '/tmp/jsonfile').run
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !(response = JSON.parse(data[1]) rescue nil).nil? &&
                   response.keys.sort & (keys = ["tag", "_jsns"].sort) == keys &&
                   response['_jsns'] == 'urn:zimbraMail' && (tag = response['tag']).size == 1 &&
                   tag.first.keys.sort & (keys = ["id", "name", "color"].sort) == keys && 
                   !(tagId = tag.first['id']).nil? &&
                   tag.first['name']  == tagname1 &&
                   tag.first['color'].to_s == tagColor
    RunCommand.new('/bin/echo', 'root',
                 "\"{\\\"TagActionRequest\\\":{\\\"_jsns\\\":\\\"urn:zimbraMail\\\"," +
                 "\\\"action\\\":{\\\"op\\\":\\\"delete\\\", \\\"id\\\":\\\"#{tagId}\\\"}}}\"",
                 '>','/tmp/jsonfile').run
  end,
                 
  v(cb("Delete tag") do
    ZMSoap.new('-m', testAccount1.name, '-p', Model::DEFAULTPASSWORD, '--json', '-f', '/tmp/jsonfile').run
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !(response = JSON.parse(data[1]) rescue nil).nil? &&
                   response.keys.sort & (keys = ["action", "_jsns"].sort) == keys &&
                   response['_jsns'] == 'urn:zimbraMail' && (action = response['action']).size == 2 &&
                   action.keys.sort & (keys = ["id", "op"].sort) == keys &&
                   action['id']  == tagId &&
                   action['op'].to_s == 'delete'
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
