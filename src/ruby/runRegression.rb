#!/bin/env ruby
#
#
#
# This will kick off regresion test
# Tai-Sheng Hwang
#
# Copyright (c) 2005 zimbra
require 'net/http'
require 'uri'

machineOne = 'qa04'
machineTwo = 'qa03'
tms = 'zqa-tms.eng.vmware.com'

#Refresh build list
url = URI.parse("http://%s/"%tms)
res = Net::HTTP.start(url.host, url.port) do |http|
  http.get('/builds/refresh_top')
end

url = URI.parse("http://%s/builds/route?redirect_to=top&branch_id=1&os_id=2"%tms)
res = Net::HTTP.start(url.host, url.port) do |http|
  http.post('/builds/route?redirect_to=top&branch_id=1&os_id=2&machine_id=%s&commit=Smoke'%machineOne, {})
end 
res = Net::HTTP.start(url.host, url.port) do |http|
  http.post('/builds/route?redirect_to=top&branch_id=1&os_id=2&machine_id=%s&commit=Full'%machineTwo, {})
end 
puts res.body
 
