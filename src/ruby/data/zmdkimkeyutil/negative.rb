#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2012 Vmware Zimbra
#
# Negative tests zmdkimkeyutil
#

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "model"
require "action/block" 
 
require "action/zmprov" 
require "action/waitqueue"
require "action/zmdkimkeyutil"
require "action/verify" 
require "action/zmprov"

include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Negative tests zmdkimkeyutil"

message = <<EOF.gsub(/\n/, "\r\n")
Date: Fri, 23 Feb 2007 16:57:04 -0800
User-Agent: Thunderbird 1.5.0.9 (Windows/20061207)
Subject: testing DKIM 
Some messages for DKIM signature testing.

EOF

uuid = nil
mselector = "slt_" + Time.now.to_i.to_s
domain2 = File.expand_path(__FILE__).sub(/.*?(data\/)(genesis\/)?(zm)?/, 'zm').sub('.rb', '').gsub(/\/|\(|\)/, '') + Time.now.to_i.to_s + "x2" + ".org"

run_on_mta = Model::Host.new(Model::Servers.getServersRunning("mta").first)
 
usage = "#{File.join(Command::ZIMBRAPATH, 'libexec', 'zmdkimkeyutil')} [-a [-b]] [-q] [-r] [-s selector] [-S] [-u [-b]] [-d domain]"
#
# Setup
#
current.setup = [

]
#
# Execution
#
current.action = [
  ZMProv.new('cd', domain2),
  
  # remove DKIM signature from domain with no signature
  v(ZMDkimkeyutil.new("-r", '-d', Model::TARGETHOST.to_s, run_on_mta)) do |mcaller,data|
      mcaller.pass = data[0] != 0 &&
                     data[1].match("Error: Domain #{Model::TARGETHOST} doesn't have DKIM enabled") 
  end,
  
  # get no DKIM info for domain
  v(ZMDkimkeyutil.new("-q", '-d', Model::TARGETHOST.to_s, run_on_mta)) do |mcaller,data|
      mcaller.pass = data[0] = 0 &&
                     data[1].match("No DKIM Information for domain #{Model::TARGETHOST}")
  end,
  
  # update DKIM signature on domain with no signature
  v(ZMDkimkeyutil.new("-u", '-d', Model::TARGETHOST.to_s, run_on_mta)) do |mcaller,data|
      mcaller.pass = data[0] != 0 &&
                     data[1].match("Error: Domain #{Model::TARGETHOST} doesn't have DKIM enabled") 
  end,

  # add with only selector
  v(ZMDkimkeyutil.new('-a', '-s', mselector, run_on_mta)) do |mcaller,data|
      mcaller.pass = data[0] != 0 &&
                     data[1].include?(usage) 
  end,
  
  # add without domain name specified
  v(ZMDkimkeyutil.new('-a', '-d', "2>&1", run_on_mta)) do |mcaller,data|
      mcaller.pass = data[0] != 0 &&
                     data[1].include?(usage) &&
                     data[1].include?("Option d requires an argument")
  end, 

  # add new DKIM signature to non existing domain
  v(ZMDkimkeyutil.new('-a', '-d', "#{rand(36**8).to_s(36)}.com", run_on_mta)) do |mcaller,data|
      mcaller.pass = data[0] != 0 &&
                     data[1].match(/Domain \w+\.com not found/)
  end,
  
  # add new DKIM signature to non existing domain with selector that looks as a valid domain
  v(ZMDkimkeyutil.new('-a', '-d', "#{rand(36**8).to_s(36)}.com", '-s', Model::TARGETHOST.to_s, run_on_mta)) do |mcaller,data|
      mcaller.pass = data[0] != 0 &&
                    data[1].match(/Domain \w+\.com not found/)
  end,
  
  # remove signature from non existing domain
  v(ZMDkimkeyutil.new("-r", '-d', "#{rand(36**8).to_s(36)}.com", run_on_mta)) do |mcaller,data|
      mcaller.pass = data[0] != 0 &&
                     data[1].match(/Domain \w+\.com not found/) 
  end,
  
  # query signature from non existing domain
  v(ZMDkimkeyutil.new("-q", '-d', "#{rand(36**8).to_s(36)}.com", run_on_mta)) do |mcaller,data|
      mcaller.pass = data[0] != 0 &&
                     data[1].match(/Domain \w+\.com not found/)  
  end,
  
  # query by non existing selector
  v(ZMDkimkeyutil.new("-q", '-s', rand(36**8).to_s(36), run_on_mta)) do |mcaller,data|
      mcaller.pass = data[0] != 0 &&
                     data[1].match(/No DKIM Information for Selector \w+/) 
  end,
  
  # key size too low
  v(ZMDkimkeyutil.new('-a', '-d', Model::TARGETHOST, "-b 512", run_on_mta)) do |mcaller,data|
      mcaller.pass = data[0] != 0 &&
                     data[1].match(/Bit size less than 2048 is not allowed, as it is insecure./) &&
                     data[1].match(/Error: Key generation failed./)
  end,
  
  # update signature on non existing domain
  v(ZMDkimkeyutil.new("-u", '-d', "#{rand(36**8).to_s(36)}.com", run_on_mta)) do |mcaller,data|
      mcaller.pass = data[0] != 0 &&
                     data[1].match(/Domain \w+\.com not found/)  
  end,  
  
  # add DKIM signature - positive
  v(ZMDkimkeyutil.new('-a', '-d', mDom = Model::TARGETHOST.to_str, '-s', mselector, run_on_mta)) do |mcaller,data|
      mcaller.pass = data[0] = 0 &&
                     data[1].match("DKIM Data added to LDAP for domain #{Model::TARGETHOST} with selector") &&
                     data[1].match("Public signature to enter into DNS:") &&
                     data[1].match(/Public signature to enter into DNS:.*_domainkey.*IN.*TXT.*v=DKIM1; k=rsa;.*p=.*;.*DKIM key .* for #{Regexp.quote(Model::TARGETHOST)}/m)
      # catch randomly created UUID
      uuid = data[1].match(/with selector (.*)\n/)[1] if mcaller.pass
  end,
  
  # add new DKIM signature to domain with a signature in place
  v(ZMDkimkeyutil.new('-a', '-d', mDom, run_on_mta)) do |mcaller,data|
      mcaller.pass = data[0] != 0 &&
                     data[1].match("Error: Domain #{Model::TARGETHOST} already has DKIM enabled.") 
  end,
  
  # delete by selector
  v(ZMDkimkeyutil.new('-r', '-s', mselector, run_on_mta)) do |mcaller,data|
      mcaller.pass = data[0] != 0 &&
                     data[1].include?(usage) 
  end,
  
  # update by selector
  v(ZMDkimkeyutil.new("-u", '-s', mselector, run_on_mta)) do |mcaller,data|
      mcaller.pass = data[0] != 0 &&
                     data[1].include?(usage) 
  end,  
  
  # add with the same selector
  v(ZMDkimkeyutil.new('-a', '-d', mDom, '-s', mselector, run_on_mta)) do |mcaller,data|
      mcaller.pass = data[0] != 0 &&
                     data[1].match("Error: Domain #{mDom} already has DKIM enabled.") 
  end,
  
  # remove DKIM signature - positive
  v(ZMDkimkeyutil.new("-r", '-d', Model::TARGETHOST.to_s, run_on_mta)) do |mcaller,data|
      mcaller.pass = data[0] = 0 &&
                     data[1].match("DKIM Data deleted in LDAP for domain #{Model::TARGETHOST}") 
  end,
  
]

#
# Tear Down
#
current.teardown = [
  ZMProv.new('dd', domain2)
]


if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance
  Engine::Simple.new(Model::TestCase.instance).run
end
