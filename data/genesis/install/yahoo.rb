#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2006 Zimbra
#
#

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model" 
require "action/block"
require "action/zmprov"
require "action/verify"
 

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Yahoo account creation"

include Action 

langDump = []
  
 
#
# Setup
#
current.setup = [
  
]
yadminone = Model::TARGETHOST.cUser("uwm01", Model::DEFAULTPASSWORD)
yadmintwo = Model::TARGETHOST.cUser("uwm02", Model::DEFAULTPASSWORD)
#
# Execution
#
current.action = [ 
  # Get local information
  cb("Fetch locales", 180) do
   result = RunCommand.new("ls", Action::Command::ZIMBRAUSER,
    File.join(Action::Command::ZIMBRAPATH,'jetty','webapps', 'zimbra','WEB-INF','classes','messages', 'AjxMsg_*')).run
    langDump = result[1].split.select do |x|
      x.include?('Ajx')
    end.map do |y|
      y =~ /AjxMsg_(.*?)\.properties/
      $1
    end
  end,
  # Create two admin accounts
  CreateAccount.new(yadminone.name, yadminone.password),
  CreateAccount.new(yadmintwo.name, yadmintwo.password),
  cb("Create Language specific accounts", 6000) do
     langDump.each do |x|
      [[Model::TARGETHOST.cUser("vmw#{x}1", Model::DEFAULTPASSWORD), "zimbraIsAdminAccount TRUE"], 
       [Model::TARGETHOST.cUser("vmw#{x}2", Model::DEFAULTPASSWORD), "zimbraIsAdminAccount TRUE"]].each do |y|
         pref = "zimbraPrefLocale #{x}"
         if(x == 'en')
            pref = ""
         end
         CreateAccount.new(y[0].name, Model::DEFAULTPASSWORD, pref, y[1]).run
      end 
     end
   end
]

#
# Tear Down
#
current.teardown = [      
 
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance, false).run  
end 
