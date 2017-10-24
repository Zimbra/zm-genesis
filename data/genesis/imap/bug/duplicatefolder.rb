#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# Duplicate folder test
#
#

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"

require "action/zmprov"
require "action/proxy" 
require "action/block"
require "action/runcommand"
require 'rexml/document'
require "net/imap"; require "action/imap" #Patch Net::IMAP library

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP Duplicate folder test bug# 29895"

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s 
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

mimap = Net::IMAP.new(Model::TARGETHOST, *Model::TARGETHOST.imap)
mid = nil
mgroupid = nil
  
include Action

 
#
# Setup
#
current.setup = [
   
]

#
# Execution
#
current.action = [  
  CreateAccount.new(testAccount.name,testAccount.password), 
  proxy(mimap.method('login'),testAccount.name,testAccount.password), 
  #Normal operation
  proxy(mimap.method('create'),"blurdybloop"), 
  RenameVerify.new(mimap, "blurdybloop","Trash/bar"),   
  v(RunCommandOnMailbox.new('/opt/zimbra/bin/mysql', Command::ZIMBRAUSER, '-X -e "select id,group_id,comment from zimbra.mailbox;"')) do |mcaller, data|
    mcaller.pass = true 
    xmlData = REXML::Document.new(data[1])
    xmlData.elements['resultset'].elements.each do |node|
      node.elements.each do |y|
        if y.attributes['name'] == 'comment' and y.text == testAccount.name
         mid =  node.elements[1].text
         mgroupid =  node.elements[2].text
        end
      end
    end
  end,
  v(cb("Duplicate Check") do 
    executeString = ['-e "select count(*) cnt, parent_id, name from mboxgroup', mgroupid, 
      '.mail_item where type=1 and mailbox_id=',mid, ' group by name, parent_id having cnt>1;"'].join('')
    response = RunCommandOnMailbox.new('/opt/zimbra/bin/mysql', Command::ZIMBRAUSER, executeString).run  
  end) do |mcaller, data|
    mcaller.pass = !data[1].include?("name")
  end 
]

#
# Tear Down
#
current.teardown = [     
  proxy(mimap.method('logout')),
  proxy(mimap.method('disconnect')),  
  DeleteAccount.new(testAccount.name)
]
if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end