#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2014 Zimbra
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
require "action/zmprov"
require "action/zmamavisd"
require "#{mypath}/install/configparser"
require 'net/smtp'

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Smtp tls test"

include Action 

(mCfg = ConfigParser.new).run
tlsLevel = nil

#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [       
  mCfg.getServersRunning('mta').map do |x|
  [   
    v(ZMProv.new('desc', '-a', 'zimbraMtaTlsSecurityLevel', h = Model::Host.new(x))) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1][/value : (\S+)/, 1].split(/\s*,\s*/).sort == ['may', 'none']
    end,
      
    cb("get settings") do
      mResult = ZMProv.new('gcf', 'zimbraMtaTlsSecurityLevel', Model::Host.new(x)).run
      tlsLevel = mResult[1][/zimbraMtaTlsSecurityLevel\s*:\s+(\S+)\n/, 1]
      mResult
    end,
      
    v(ZMProv.new('mcf', 'zimbraMtaTlsSecurityLevel', 'none', h)) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1].empty?
    end,
      
    v(ZMMtactl.new('reload', h)) do |mcaller, data|
      mcaller.pass = data[0] == 0
    end,
      
    v(cb('tls none check') do
      begin
        smtp = Net::SMTP.start(x, 25)
        smtp.starttls
      rescue
        $!
      end
    end) do |mcaller, data|
      mcaller.pass = data.kind_of?(Net::SMTPSyntaxError) && data.message =~ /command not implemented/
    end,
      
    v(ZMProv.new('mcf', 'zimbraMtaTlsSecurityLevel', 'may', h)) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1].empty?
    end,
      
    v(ZMMtactl.new('reload', h)) do |mcaller, data|
      mcaller.pass = data[0] == 0
    end,
      
    v(cb('tls none check') do
      begin
        smtp = Net::SMTP.start(x, 25)
        smtp.starttls
      rescue
        $!
      end
    end) do |mcaller, data|
      mcaller.pass = data.kind_of?(Net::SMTP::Response) && data.string =~ /Ready to start TLS/
    end,
    
    cb("restore settings") do
      if tlsLevel != 'may'
      [  
        v(ZMProv.new('mcf', 'zimbraMtaTlsSecurityLevel', tlsLevel, h)) do |mcaller, data|
          mcaller.pass = data[0] == 0 && data[1].empty?
        end,

        v(ZMMtactl.new('reload', h)) do |mcaller, data|
          mcaller.pass = data[0] == 0
        end
      ]
      end
    end
    ]
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