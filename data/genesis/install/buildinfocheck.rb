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

mypath = 'data'
if($0 =~ /data\/genesis/)
  mypath += '/genesis'
end

require "model"
require "action/block"
require "action/verify"
require 'model/user'
require 'model/json/request'
require 'model/json/loginrequest'
require 'json'
require 'action/json/login'
require 'action/json/getversioninfo'
require "action/zmlocalconfig"
require "#{mypath}/install/utils"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Build info check"


include Action
include Action::Json
include Model
include Model::Json


#
# Setup
#
current.setup = [
  
]
   
#
# Execution
#
current.action = [ 
v(cb("Build info check") do
    proxy = ZMProv.new('gas', 'imapproxy').run[1].split(/\n/)
    store = ZMProv.new('gas', 'mailbox').run[1].split(/\n/)
    server = (store - proxy).first rescue nil
    server = ZMLocal.new('zimbra_server_hostname').run if server.nil?
    toks = server.split('.')
    target = Host.new(toks[0], toks[1..-1].join('.'))
    admin = Utils::getAdmins.first
    alogin = AdminLogin.new(AdminLoginRequest.new(admin), target).run
    mResult = GetVersionInfo.new(admin, target).run
    next(mResult) if mResult[0] != 0
    mResult
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1]['version'].include?(data[1]['platform'])
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      if data[0] != 0
        mcaller.badones = {'Execution error' => {"SB" => 'Success, exit code 0', "IS" => data[1]}}
      else
        mcaller.badones = {'build version' => {"IS" => data[1]['version'],
                                               "SB" => "no platform info included(#{data[1]['platform']})"}}
      end
    end
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