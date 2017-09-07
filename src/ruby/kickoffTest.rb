#!/bin/env ruby
#
# This will kick off regresion test
# Tai-Sheng Hwang
#
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2007 Zimbra
#
#
# Kick off script for daily automation
#
# Arguments
# machineOne = name of the machine 'qa04'
# branch = name of the branch 'FRANK'.  This is case sensitive
# os = name of the operating system 'RHEL4'
# test_type = 'type of the test'
# oss 'Y' oss build, 'N' network build
#

require 'net/http'
require 'uri'
require 'xmlrpc/client'
require 'yaml'

PTMS = ENV['tms'] || 'zqa-tms.eng.vmware.com'
tmsMachineUrl = 'http://%s/xmlrpc/api'%PTMS
machineOne, branch, os, test_type, oss, note = ARGV
puts "Running test on %s %s %s %s %s %s" % [machineOne, branch, os, test_type, oss, note];
server = XMLRPC::Client.new2(tmsMachineUrl)

#Get Target Branch Information
tBranchObj = YAML.load(server.call("machine.Getbranchbyname", branch))

#Get Architecture Information
tArchObj = YAML.load(server.call("machine.Getarchbyname", os))


#Get particular build if required
case oss
  when 'Y'
     mFilter = 'OSS'
  when 'Z'
     mFilter = 'ZDESKTOP'
  when 'O'
     mFilter = 'OCTOPUS'
  else
     mFilter = 'NETWORK'
end

if(note)
   tBuildObj = YAML.load(server.call("machine.Getbuildbynotenobranch", note, os, mFilter))
else
   tBuildObj = YAML.load(server.call("machine.Getlatestbuild", os, branch, mFilter))
end


#puts YAML.dump(tBranchObj)
#puts YAML.dump(tArchObj)
#puts YAML.dump(tBuildObj)

if(tBuildObj)
  testLink = '/builds/route?redirect_to=top&build=%s&branch_id=%s&os_id=%s&machine_id=%s&commit=%s'%[tBuildObj['id'], tBranchObj['id'], tArchObj['id'], machineOne, URI.escape(test_type)]
else
  testLink = '/builds/route?redirect_to=top&branch_id=%s&os_id=%s&machine_id=%s&commit=%s'%[tBranchObj['id'], tArchObj['id'], machineOne, URI.escape(test_type)]
end

if (oss == 'Y')
  testLink = testLink + '&OSS=yes'
end

url = URI.parse("http://%s/builds/route?redirect_to=top&branch_id=1&os_id=2"%PTMS)
res = Net::HTTP.start(url.host, url.port) do |http|
  http.post(testLink, {})
end
puts res.body
