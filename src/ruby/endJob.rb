#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2010 VMWARE
#
# End particular job
#
require 'net/http'
require 'uri'

PTMS = ENV['tms'] || 'zqa-tms.eng.vmware.com'

jobID, tms = ARGV
puts "Ending job %s" %[jobID]
tms = tms || PTMS

url = URI.parse("http://%s/jobs/endJob/%s"%[tms, jobID])
begin
  res = Net::HTTP.start(url.host, url.port) do |http|   
    http.read_timeout = 60000
    http.post(url.path, {}) 
  end
  puts res.body
rescue Errno::ECONNREFUSED => e
  sleep(60)
  retry
end

