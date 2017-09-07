#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# Copyright (c) 2005 zimbra
# 
# Part of daily cron job, refresh build system link and rebuild qa00 entry
# 
require 'net/http'
require 'uri'
require 'yaml'

PTMS = ENV['tms'] || 'zqa-tms.eng.vmware.com'

refreshLink = 'zre-matrix.eng.vmware.com'
url = URI.parse("http://%s/"%refreshLink)
res = Net::HTTP.start(url.host, url.port) do |http|
   http.read_timeout=600
   http.get('/cgi-bin/build/new/fixlinks.cgi')
end

puts res.body

#Refresh build list
url = URI.parse("http://%s/"%PTMS)
res = Net::HTTP.start(url.host, url.port) do |http|
  http.read_timeout=600
  http.get('/builds/refresh_top')
end
puts res.bod
