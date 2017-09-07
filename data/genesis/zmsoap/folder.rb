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
# zmsoap folder creation,deletion and modification requests
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
current.description = "zmsoap folder requests"

timeNow = Time.now.to_i.to_s
prefix = File.expand_path(__FILE__).sub(/.*?(data\/)(genesis\/)?(zm)?/, 'zm').sub('.rb', '').gsub(/\/|\(|\)/, '')
domain = Model::Domain.new("#{prefix}dom#{timeNow}.com")
testAccount1 = domain.cUser(prefix + 'acct1' + timeNow)
folder1 = prefix + "folder1" + timeNow
folder2 = prefix + "folder2" + timeNow
newfolder2 = prefix + "newfolder2" + timeNow
folder3 = prefix + "folder3" + timeNow
inboxId = "" # Inbox folder ID
fId = "" # Newly created folder ID
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

  cb("Get Inbox folder ID") do
    fResult = ZMSoapXml.new('-m', testAccount1.name, '-p', Model::DEFAULTPASSWORD, "GetFolderRequest/folder/@path=Inbox").run
    inboxId = (fResult[1].elements['GetFolderResponse'].get_elements('folder')).first.attributes['id'] rescue 2
  end,
    
  RunCommand.new('/bin/echo', 'root', "\"{\\\"GetFolderRequest\\\":{\\\"_jsns\\\":\\\"urn:zimbraMail\\\", \\\"folder\\\":{\\\"path\\\":\\\"Inbox\\\"}}}\"", '>','/tmp/jsonfile'),
    
  v(ZMSoap.new('-m', testAccount1.name, '-p', Model::DEFAULTPASSWORD, '--json', '-f', '/tmp/jsonfile')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !(response = JSON.parse(data[1]) rescue nil).nil? &&
                   response.keys.sort & (keys = ["folder", "_jsns"].sort) == keys &&
                   response['_jsns'] == 'urn:zimbraMail' && response['folder'].size == 1 &&
                   response['folder'].first.keys.include?('id') && 
                   response['folder'].first['id'] == inboxId
  end,

  v(cb("Create folder under Inbox") do
    ZMSoapXml.new('-m', testAccount1.name, '-p', Model::DEFAULTPASSWORD, "CreateFolderRequest/folder name=#{folder1} ../l=#{inboxId}").run
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].nil? &&
                   (details = data[1].elements['CreateFolderResponse'].get_elements('folder')).first.attributes['name'] == folder1 &&
                   !(fId = details.first.attributes['id']).nil? &&
                   details.first.attributes['l'] == inboxId
  end,

  v(cb("Create duplicate folder under Inbox") do
    mResult = ZMSoapXml.new('-v', '-m', testAccount1.name, '-p', Model::DEFAULTPASSWORD, "CreateFolderRequest/folder name=#{folder1} ../l=#{inboxId}").run
    end) do |mcaller, data|
      mcaller.pass = data[0] != 0
  end,

  v(cb("Rename folder") do
    mResult = ZMSoapXml.new('-m', testAccount1.name, '-p', Model::DEFAULTPASSWORD, "FolderActionRequest/action/ @op=rename @name=#{newfolder2} @id=#{fId}").run
    end) do |mcaller, data|
      mcaller.pass = data[0] == 0 && !data[1].nil? &&
                     (details = data[1].elements['FolderActionResponse'].get_elements('action')).first.attributes['op'] == "rename" &&
                     details.first.attributes['id'] == fId
  end,

  v(cb("Delete folder") do
    mResult = ZMSoapXml.new('-m', testAccount1.name, '-p', Model::DEFAULTPASSWORD, "FolderActionRequest/action/ @op=delete @id=#{fId}").run
    end) do |mcaller, data|
      mcaller.pass = data[0] == 0 && !data[1].nil? &&
                     (details = data[1].elements['FolderActionResponse'].get_elements('action')).first.attributes['op'] == "delete" &&
                     details.first.attributes['id'] == fId
  end,
    
  RunCommand.new('/bin/echo', 'root',
                 "\"{\\\"CreateFolderRequest\\\":{\\\"_jsns\\\":\\\"urn:zimbraMail\\\"," +
                 "\\\"folder\\\":{\\\"name\\\":\\\"#{folder1}\\\", \\\"l\\\":\\\"2\\\"}}}\"",
                 '>','/tmp/jsonfile'),
    
  v(cb("Create folder under Inbox") do
    ZMSoap.new('-m', testAccount1.name, '-p', Model::DEFAULTPASSWORD, '--json', '-f', '/tmp/jsonfile').run
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !(response = JSON.parse(data[1]) rescue nil).nil? &&
                   response.keys.sort & (keys = ["folder", "_jsns"].sort) == keys &&
                   response['_jsns'] == 'urn:zimbraMail' && response['folder'].size == 1 &&
                   response['folder'].first.keys.include?('id') && 
                   !(fId = response['folder'].first['id']).nil? &&
                   response['folder'].first['l']  == inboxId
  end,
    
  #rename folder
  #delete folder
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
