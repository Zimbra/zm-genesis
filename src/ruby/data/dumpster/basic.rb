#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2012 VMware
#
# Test dumpstertest
#

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/, "").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata,  'src',  'ruby')) #append library path
end

require "action/command"
require "action/clean"
require "action/block"
require "action/zmprov"
require "action/verify"
require "action/runcommand"
require "model"
require "action/zmlmtpinject"
require "action/zmsoap"
require "action/zmmailbox"

include Action

#
# Global variable declaration
#

current = Model::TestCase.instance()
current.description = "Test dumpstertest"

timeNow = Time.now.to_i.to_s
prefix = File.expand_path(__FILE__).sub(/.*?(data\/)(genesis\/)?(zm)?/, 'zm').sub('.rb', '').gsub(/\/|\(|\)/, '')
domain = Model::Domain.new("#{prefix}dom#{timeNow}.com")
testAccount1 = domain.cUser(prefix + 'acct1' + timeNow)
testAccount2 = domain.cUser(prefix + 'acct2' + timeNow)
dumpstercos = prefix+'dumpstercos'+timeNow
subject1 = prefix+'messagesubject'+timeNow
mFile = File.join(Command::ZIMBRAPATH, 'data', 'tmp', 'msg01.txt')
mId = ""
flag = 1
contactFirstName = 'firstname'+Time.now.to_i.to_s
contactLastName = 'lastname'+Time.now.to_i.to_s
contactEmail = 'email'+Time.now.to_i.to_s+'domain.com'
cId = ""
taskSubject = 'taskSubject'+Time.now.to_i.to_s
taskContent = 'taskContent'+Time.now.to_i.to_s
tasksId = ""
tId = ""
taskId = ""
calItemId = ""
apptSubject1 = prefix + "subject" + timeNow
apptContent1 = prefix + "content" + timeNow
apptLocation1 = prefix + "location" + timeNow
apptStartTime = (Time.now + 3*60*60).strftime("%Y%m%dT%H0000")
apptEndTime = (Time.now + 4*60*60).strftime("%Y%m%dT%H0000")
apptId = ""

#
# Setup
#
current.setup = [
]
#
# Execution
#
current.action = [

  # Test case : 1. Create a COS and created account associated to COS 2. change zimbraDumpsterEnabled COS attribute to TRUE
  # 3.Inject Message to account 4. Delete Message 5. Search message without --dumpster option 6. Seach message in dumpster folder 7. Recover from Dumpster to Inbox 8. Verify Message is in Inbox.
  v(cb("Create a COS and associate account with the COS") do
    cosResult = ZMProv.new('cc',dumpstercos).run
    cosId = cosResult[1]
    ZMProv.new('cd', domain.name).run
    ZMProv.new('ca', testAccount1.name, Model::DEFAULTPASSWORD, 'zimbraCOSId', cosId).run
    ZMProv.new('ca', testAccount2.name, Model::DEFAULTPASSWORD).run
	end) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,

  v(ZMProv.new('mc', dumpstercos, 'zimbraDumpsterEnabled','TRUE')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,

  cb("Create message file") do
    rawMessage = IO.readlines(File.join(Model::DATAPATH, 'email01', 'msg01.txt'))
    message = rawMessage.collect do |w|
                w.gsub(/To: \S+/, "To: #{testAccount1.name}")
              end.collect do |w|
                w.gsub(/Subject: \S+/, "Subject: #{subject1}")
              end.collect do |w|
                w.gsub(/From: \S+/, 'From: genesis@zimbratest.com')
              end
    File.open(mFile, "w") do |file|
      file.puts message.join('')
    end
  end,

  ZMLmtpinject.new('-r', testAccount1.name, '-s', 'genesis@zimbratest.com', mFile),

  Action::WaitQueue.new,

  cb('Get the Message injected in previous step') do
    mResult = ZMailAdmin.new('-m', testAccount1.name, 's', '-t', 'message', 'in:inbox').run
    res = mResult[1].split(/\n/).last
    next mResult if res !~ /\d+\s+mess\s+genesis\s+#{subject1}/
    mId = res[/\d+\.\s*(\d+)\s+mess/, 1]
  end,

  v(cb("Delete the message search in previous step") do
    mId = mId.to_s.chomp
    data  = ZMMail.new('-z', '-m', testAccount1.name, 'dm', mId).run
  end) do |mcaller,data|
    mcaller.pass = (data[0] == 0)
  end,

  v(cb("Search message without --dumpster option") do
    data  = ZMMail.new('-z', '-m', testAccount1.name, 'search', '-t', 'message', subject1).run
  end) do |mcaller,data|
    mcaller.pass = data[0] == 0 && ZMMail.outputOnly(data[1]).split(/\n/).last =~ /num:\s0,\smore:\sfalse/
  end,

  v(cb("Search message in dumpster") do
    data  = ZMMail.new('-z', '-m', testAccount1.name, 'search', '--dumpster', '-t', 'message', subject1).run
  end) do |mcaller,data|
    mcaller.pass = data[0] == 0 && ZMMail.outputOnly(data[1]).split(/\n/).last =~ /1\.\s+#{mId}\s+mess/
  end,

  v(cb("Recover from Dumpster") do
    mId = mId.to_s.chomp
    data  = ZMMail.new('-z', '-m', testAccount1.name, 'ri', mId,'/Inbox').run
  end) do |mcaller,data|
    mcaller.pass = (data[0] == 0)
  end,

  v(cb('Verify the message is present in Inbox') do
    mResult = ZMailAdmin.new('-m', testAccount1.name, 's', '-t', 'message', 'in:inbox').run
    res = mResult[1].split(/\n/).last
    next mResult if res !~ /\d+\s+mess\s+genesis\s+#{subject1}/
    mId = res[/\d+\.\s*(\d+)\s+mess/, 1]
    flag = 0 if mId.to_s =~ /\d+/
    [0,flag]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && flag == 0
  end,

  # Test case : 1. Create a COS and created account associated to COS 2. change zimbraDumpsterEnabled COS attribute to TRUE (Steps 1 & 2 added in previous testcase)
  # 3. Create contact 4. Delete Contact 5. Search the contact without --dumpster option. 6. Search the contact in dumpster folder 7. Recover from Dumpster to Contacts 8. Verify Contact is restored.
  cb("Create a contact using zmsoap request") do
    mResult = ZMSoapXml.new('-m', testAccount1.name, '-p', Model::DEFAULTPASSWORD, "CreateContactRequest/cn",
                            "a=#{contactFirstName} @n=firstname",
                            "../a=#{contactLastName} @n=lastname",
                            "../a=#{contactEmail} @n=email").run
	  next mResult if mResult[0] != 0
	  cId = (mResult[1].elements['CreateContactResponse'].get_elements('cn')).first.attributes['id']
  end,

  v(cb("Delete the contact created in previous step") do
    cId = cId.to_s.chomp
    data  = ZMMail.new('-z', '-m', testAccount1.name, 'dct', cId).run
  end) do |mcaller,data|
    mcaller.pass = (data[0] == 0)
  end,

  v(cb("Search contact without --dumpster option") do
    data  = ZMMail.new('-z', '-m', testAccount1.name, 'search', '-t', 'contact', contactFirstName).run
  end) do |mcaller,data|
    mcaller.pass = data[0] == 0 && ZMMail.outputOnly(data[1]).split(/\n/).last =~ /num:\s0,\smore:\sfalse/
  end,

  v(cb("Search contact in dumpster") do
    data  = ZMMail.new('-z', '-m', testAccount1.name, 'search', '--dumpster', '-t', 'contact', contactFirstName).run
  end) do |mcaller,data|
    mcaller.pass = data[0] == 0 && ZMMail.outputOnly(data[1]).split(/\n/).last =~ /1\.\s+#{cId}\s+cont/
  end,

  v(cb("Recover contact from Dumpster") do
    data  = ZMMail.new('-z', '-m', testAccount1.name, 'ri', cId,'/Contacts').run
  end) do |mcaller,data|
    mcaller.pass = (data[0] == 0)
  end,

  v(ZMSoapXml.new('-m', testAccount1.name, '-p', Model::DEFAULTPASSWORD, "SearchRequest/query=#{contactEmail} ../types=contact")) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].nil? &&
                   (details = data[1].elements['SearchResponse'].get_elements('cn/a')).size == 3 &&
                   details.collect{|a| [a.attributes['n'], a.text]}.sort == [['email', contactEmail],
                                                                             ['lastname', contactLastName],
                                                                             ['firstname', contactFirstName],
                                                                            ].sort
  end,

  # Test case : 1. Create a COS and created account associated to COS 2. change zimbraDumpsterEnabled COS attribute to TRUE (Steps 1 & 2 added in previous testcase)
  # 3. Create a task 4. Delete task 5. Search task without --dumpster 6. Search the task in dumpster folder 7. Recover from Dumpster to tasks folder 8. Verify task is restored.
  cb("Get Task folder ID") do
    mResult = ZMSoapXml.new('-m', testAccount1.name, '-p', Model::DEFAULTPASSWORD, "GetFolderRequest/folder/@path=Tasks").run
    next mResult if mResult[0] != 0
    tasksId = (mResult[1].elements['GetFolderResponse'].get_elements('folder')).first.attributes['id']
  end,

  cb("Create a Task") do
    mResult = ZMSoapXml.new('-m', testAccount1.name, '-p', Model::DEFAULTPASSWORD, "CreateTaskRequest/m l=#{tasksId}",
                            "../inv/comp @priority=5 @name=#{taskSubject}",
                            "../../su=#{taskSubject}",
                            "../../mp @ct=\"text\/plain\" content=#{taskContent}").run
    next mResult if mResult[0] != 0
    tId = mResult[1].elements['CreateTaskResponse'].attributes['invId']
		taskId = mResult[1].elements['CreateTaskResponse'].attributes['calItemId']
  end,

  v(cb("Delete the task created in previous step") do
    tId = tId.to_s.chomp
    data  = ZMMail.new('-z', '-m', testAccount1.name, 'di', tId).run
  end) do |mcaller,data|
    mcaller.pass = (data[0] == 0)
  end,

  v(cb("Search task without --dumpster option") do
    data  = ZMMail.new('-z', '-m', testAccount1.name, 'search', '-t', 'task', taskSubject).run
  end) do |mcaller,data|
    mcaller.pass = data[0] == 0 && ZMMail.outputOnly(data[1]).split(/\n/).last =~ /num:\s0,\smore:\sfalse/
  end,

  v(cb("Search task in dumpster") do
    data  = ZMMail.new('-z', '-m', testAccount1.name, 'search', '--dumpster', '-t', 'task', taskSubject).run
  end) do |mcaller,data|
    mcaller.pass = data[0] == 0 && ZMMail.outputOnly(data[1]).split(/\n/).last =~ /1\.\s+#{taskId}\s+task/
  end,

  v(cb("Recover task from Dumpster") do
    mId = mId.to_s.chomp
    data  = ZMMail.new('-z', '-m', testAccount1.name, 'ri', tId,'/Tasks').run
  end) do |mcaller,data|
    mcaller.pass = (data[0] == 0)
  end,

  v(ZMSoapXml.new('-m', testAccount1.name, '-p', Model::DEFAULTPASSWORD, "SearchRequest/query=#{taskSubject} ../types=task")) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].nil? &&
                   data[1].elements['SearchResponse'].get_elements('task').first.attributes['name'] == taskSubject
  end,

  # Test case : 1. Create a COS and created account associated to COS 2. change zimbraDumpsterEnabled COS attribute to TRUE (Steps 1 & 2 added in previous testcase)
  # 3. Create an appointment 4. Delete appointment 5. Search appointment without --dumpster 6. Search appointment in dumpster folder 7. Recover from Dumpster to Calendar folder 8. Verify appointment is restored.
  cb("Create an appointment with attendee") do
    mResult = ZMSoapXml.new('-m', testAccount1.name, '-p', Model::DEFAULTPASSWORD, "CreateAppointmentRequest/m",
                            "inv @method=REQUEST @type=event @fb=B @name=#{apptSubject1} @loc=#{apptLocation1}",
                            "s @d=#{apptStartTime}",
                            "../e @d=#{apptEndTime}",
                            "../at @role=OPT @ptst=NE @rsvp=1 @a=#{testAccount2.name}",
                            "../or @a=#{testAccount1.name}",
                            "../../e @a=#{testAccount2.name} @t=t",
                            "../mp @content-type=\"text\/plain\" content=#{apptContent1}").run
    next mResult if mResult[0] != 0
    apptId = mResult[1].elements['CreateAppointmentResponse'].attributes['apptId']
  end,

  v(cb("Delete the appointment created in previous step") do
    apptId = apptId.to_s.chomp
    data  = ZMMail.new('-z', '-m', testAccount1.name, 'di', apptId).run
  end) do |mcaller,data|
    mcaller.pass = (data[0] == 0)
  end,

  v(cb("Search appointment without --dumpster option") do
    data  = ZMMail.new('-z', '-m', testAccount1.name, 'search', '-t', 'appointment', apptSubject1).run
  end) do |mcaller,data|
    mcaller.pass = data[0] == 0 && ZMMail.outputOnly(data[1]).split(/\n/).last =~ /num:\s0,\smore:\sfalse/
  end,

  v(cb("Search appointment in dumpster") do
    data  = ZMMail.new('-z', '-m', testAccount1.name, 'search', '--dumpster', '-t', 'appointment', apptSubject1).run
  end) do |mcaller,data|
    mcaller.pass = data[0] == 0 && ZMMail.outputOnly(data[1]).split(/\n/).last =~ /1\.\s+#{apptId}\s+appo/
  end,

  v(cb("Recover appointment from Dumpster") do
    mId = mId.to_s.chomp
    data  = ZMMail.new('-z', '-m', testAccount1.name, 'ri', apptId,'/Calendar').run
  end) do |mcaller,data|
    mcaller.pass = (data[0] == 0)
  end,

  v(ZMSoapXml.new('-m', testAccount1.name, '-p', Model::DEFAULTPASSWORD, "SearchRequest/query=#{apptSubject1} ../types=appointment")) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].nil? &&
                   data[1].elements['SearchResponse'].get_elements('appt').first.attributes['name'] == apptSubject1
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

