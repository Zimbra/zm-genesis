#!/bin/env ruby
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
# do a ping waiting of staf system
# part of reboot nt looop
#
require 'timeout'
machine, timeout = ARGV
timeout = timeout || 300
status = Timeout::timeout(timeout.to_i) do
  exitCode = 1
  while(!exitCode.zero?)
    `staf #{machine} ping ping`
    exitCode = $?.to_i
    sleep 5 unless exitCode.zero?
  end
end
