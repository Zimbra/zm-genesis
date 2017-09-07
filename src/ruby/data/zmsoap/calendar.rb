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
# zmsoap for calendar/appointment related operations.
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
current.description = "zmsoap calendar/appointment requests"

timeNow = Time.now.to_i.to_s
prefix = File.expand_path(__FILE__).sub(/.*?(data\/)(genesis\/)?(zm)?/, 'zm').sub('.rb', '').gsub(/\/|\(|\)/, '')
domain = Model::Domain.new("#{prefix}dom#{timeNow}.com")
testAccount1 = domain.cUser(prefix + 'acct1' + timeNow)
testAccount2 = domain.cUser(prefix + 'acct2' + timeNow)
subject1 = prefix + "subject" + timeNow
content1 = prefix + "content" + timeNow
location1 = prefix + "location" + timeNow
startTime = (Time.now + 3*60*60).strftime("%Y%m%dT%H0000")
endTime = (Time.now + 4*60*60).strftime("%Y%m%dT%H0000")
apptId = ""
invId = ""
newsubject1 = prefix + "subject" + timeNow
newlocation1 = prefix + "location" + timeNow
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

  v(cb("Create an appointment with attendee and ensure that appointment is created") do
    mResult = ZMSoapXml.new('-m', testAccount1.name, '-p', Model::DEFAULTPASSWORD, "CreateAppointmentRequest/m",
                            "inv @method=REQUEST @type=event @fb=B @name=#{subject1} @loc=#{location1}",
                            "s @d=#{startTime}",
                            "../e @d=#{endTime}",
                            "../at @role=OPT @ptst=NE @rsvp=1 @a=#{testAccount2.name}",
                            "../or @a=#{testAccount1.name}",
                            "../../e @a=#{testAccount2.name} @t=t",
                            "../mp @content-type=\"text\/plain\" content=#{content1}").run
    next mResult if mResult[0] != 0
    apptId = mResult[1].elements['CreateAppointmentResponse'].attributes['apptId']
    invId = mResult[1].elements['CreateAppointmentResponse'].attributes['invId']
    mResult = ZMSoapXml.new('-m', testAccount1.name, '-p', Model::DEFAULTPASSWORD, "GetAppointmentRequest", "@id=#{invId}").run
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].nil? &&
                   data[1].elements['GetAppointmentResponse'].get_elements('appt').first.attributes['id'] == apptId
  end,

  v(cb("Modify existing appointment and ensure that appointment is been modified") do
    mResult = ZMSoapXml.new('-v', '-m', testAccount1.name, '-p', Model::DEFAULTPASSWORD, "ModifyAppointmentRequest @id=#{invId} m",
                            "inv @method=REQUEST @type=event @fb=B @name=#{newsubject1} @loc=#{newlocation1}",
                            "s @d=#{startTime}",
                            "../e @d=#{endTime}",
                            "../at @role=OPT @ptst=NE @rsvp=1 @a=#{testAccount2.name}",
                            "../or @a=#{testAccount1.name}",
                            "../../e @a=#{testAccount2.name} @t=t",
                            "../mp @content-type=\"text\/plain\" content=#{content1}").run
    next mResult if mResult[0] != 0
    apptId = mResult[1].elements['ModifyAppointmentResponse'].attributes['apptId']
    invId = mResult[1].elements['ModifyAppointmentResponse'].attributes['invId']
    mResult = ZMSoapXml.new('-m', testAccount1.name, '-p', Model::DEFAULTPASSWORD, "GetAppointmentRequest", "@id=#{invId}").run
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].nil? &&
                   data[1].elements['GetAppointmentResponse'].get_elements('appt/inv/comp').first.attributes['apptId'] == apptId &&
                   data[1].elements['GetAppointmentResponse'].get_elements('appt/inv/comp').first.attributes['name'] == newsubject1 &&
                   data[1].elements['GetAppointmentResponse'].get_elements('appt/inv/comp').first.attributes['loc'] == newlocation1
  end,

  v(cb("Cancel existing appointment") do
    ZMSoapXml.new('-v', '-m', testAccount1.name, '-p', Model::DEFAULTPASSWORD, "CancelAppointmentRequest @id=#{invId} @comp=0").run
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].elements.size == 1 && !data[1].elements['CancelAppointmentResponse'].nil?
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
