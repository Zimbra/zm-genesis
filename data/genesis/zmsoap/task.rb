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
# zmsoap for task related operations
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
current.description = "zmsoap task requests"

timeNow = Time.now.to_i.to_s
prefix = File.expand_path(__FILE__).sub(/.*?(data\/)(genesis\/)?(zm)?/, 'zm').sub('.rb', '').gsub(/\/|\(|\)/, '')
domain = Model::Domain.new("#{prefix}dom#{timeNow}.com")
testAccount1 = domain.cUser(prefix + 'acct1' + timeNow)
subject1 = prefix + "subject" + timeNow
content1 = prefix + "content" + timeNow
newsubject1 = prefix + "newsubject" + timeNow
newlocation1 = prefix + "newlocation" + timeNow
startTime = Time.now
endTime = Time.now + 60 * 30
tId = ""
tasksId = ""
calItemId = ""
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

  cb("Get Task folder ID") do
    mResult = ZMSoapXml.new('-m', testAccount1.name, '-p', Model::DEFAULTPASSWORD, "GetFolderRequest/folder/@path=Tasks").run
    next mResult if mResult[0] != 0
    tasksId = (mResult[1].elements['GetFolderResponse'].get_elements('folder')).first.attributes['id']
  end,

  v(cb("Create a Task and Verify that task created") do
    mResult = ZMSoapXml.new('-m', testAccount1.name, '-p', Model::DEFAULTPASSWORD, "CreateTaskRequest/m l=#{tasksId}",
                            "../inv/comp @priority=5 @name=#{subject1}",
                            "../../su=#{subject1}",
                            "../../mp @ct=\"text\/plain\" content=#{content1}").run
    next mResult if mResult[0] != 0
    tId = mResult[1].elements['CreateTaskResponse'].attributes['invId']
    calItemId = mResult[1].elements['CreateTaskResponse'].attributes['calItemId']
    mResult = ZMSoapXml.new('-m', testAccount1.name, '-p', Model::DEFAULTPASSWORD, "GetTaskRequest", "@id=#{tId}").run
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].nil? &&
                   data[1].elements['GetTaskResponse'].get_elements('task/inv/comp').first.attributes['calItemId'] == calItemId
  end,

  v(cb("Modify existing created task(change subject and location)") do
    mResult = ZMSoapXml.new('-m', testAccount1.name, '-p', Model::DEFAULTPASSWORD, "ModifyTaskRequest @id=#{tId} m l=#{tasksId}",
                            "../inv/comp @priority=5 @name=#{newsubject1} @loc=#{newlocation1}",
                            "../../su=#{newsubject1}",
                            "../../mp @ct=\"text\/plain\" content=#{content1}").run
    next mResult if mResult[0] != 0
    tId = mResult[1].elements['ModifyTaskResponse'].attributes['invId']
    calItemId = mResult[1].elements['ModifyTaskResponse'].attributes['calItemId']
    mResult = ZMSoapXml.new('-m', testAccount1.name, '-p', Model::DEFAULTPASSWORD, "GetTaskRequest", "@id=#{tId}").run
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].nil? &&
                   data[1].elements['GetTaskResponse'].get_elements('task/inv/comp').first.attributes['calItemId'] == calItemId &&
                   data[1].elements['GetTaskResponse'].get_elements('task/inv/comp').first.attributes['name'] == newsubject1 &&
                   data[1].elements['GetTaskResponse'].get_elements('task/inv/comp').first.attributes['loc'] == newlocation1
  end,

  v(cb("Cancel existing created task") do
    ZMSoapXml.new('-v', '-m', testAccount1.name, '-p', Model::DEFAULTPASSWORD, "CancelTaskRequest @id=#{tId} @comp=0").run
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].nil?
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
