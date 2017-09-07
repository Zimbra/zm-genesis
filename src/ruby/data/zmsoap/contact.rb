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
# zmsoap contact operations
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
current.description = "zmsoap contact operations"

timeNow = Time.now.to_i.to_s
prefix = File.expand_path(__FILE__).sub(/.*?(data\/)(genesis\/)?(zm)?/, 'zm').sub('.rb', '').gsub(/\/|\(|\)/, '')
domain = Model::Domain.new("#{prefix}dom#{timeNow}.com")
testAccount1 = domain.cUser(prefix + 'acct1' + timeNow)
contactFirstName = 'firstname'+Time.now.to_i.to_s
contactLastName = 'lastname'+Time.now.to_i.to_s
contactEmail = 'email'+Time.now.to_i.to_s+'domain.com'
newcontactEmail1 = 'newemail1'+Time.now.to_i.to_s+'domain.com'
cId = ""
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

  v(cb("Modify a contact created in previous step") do
    ZMSoapXml.new('-m', testAccount1.name, '-p', Model::DEFAULTPASSWORD, "ModifyContactRequest/cn @id=#{cId} a=#{newcontactEmail1} @n=email").run
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].nil? &&
                   data[1].elements['ModifyContactResponse'].elements["cn/a[@n='email']"].text == newcontactEmail1
  end,

  v(cb("Delete a contact created in previous step") do
    ZMSoapXml.new('-m', testAccount1.name, '-p', Model::DEFAULTPASSWORD, "ContactActionRequest/action @id=#{cId} @op=delete").run
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].nil? &&
                   data[1].elements['ContactActionResponse'].elements['action'].attributes.sort == [['op', 'delete'],['id', cId]].sort
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
