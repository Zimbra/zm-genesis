#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# This will kick off upgrade test
# Tai-Sheng Hwang
#
# Copyright (c) 2006 zimbra
require 'net/http'
require 'uri'

machineOne, branch_id, os_id, test_type, build_id , run_oss= ARGV
puts "Running test on %s %s %s %s" % [machineOne, branch_id, os_id, test_type, run_oss];

PTMS = ENV['tms'] || 'zqa-tms.eng.vmware.com'

url = URI.parse("http://%s/builds/route?redirect_to=top&branch_id=1&os_id=2"%PTMS)
res = Net::HTTP.start(url.host, url.port) do |http|
  urlString = '/builds/route?redirect_to=top&branch_id=%s&os_id=%s&machine_id=%s&commit=%s&build=%s'%[branch_id, os_id, machineOne,
test_type, build_id]
  if(run_oss.include?('Y'))
    urlString = urlString + '&OSS=yes'
  else
    urlString = urlString + '&NETWORK=yes'        
  end
  http.post(urlString, {})

end
puts res.body
