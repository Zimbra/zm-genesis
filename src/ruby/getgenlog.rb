#!/usr/bin/env ruby
#
# This require Net::SSH
#
require 'rubygems'
require 'net/ssh'
require 'yaml'

hostname = ARGV.first
PASS = ARGV[1]
Net::SSH.start(hostname, 'root', :password => PASS) do |ssh|
        result = ssh.exec!('ps -elf | grep runtest.rb | grep -v grep')
        fileName = File.join(result.split(/ +/).last.chomp, 'summary.txt')
        puts fileName
        exec "vim scp://root@%s/%s"%[hostname, fileName]
end
