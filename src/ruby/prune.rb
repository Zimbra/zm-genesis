#!/bin/env ruby /u/apps/TMS/current/script/runner
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2011 VMware
#
# clean up old test logs
# 
require 'rubygems'
require 'file/find'
require 'yaml'
require 'fileutils'
rule = File::Find.new(
                      :pattern => "*{_FOSS, _NETWORK, _ZCA, _ZDESKTOP, _OCTOPUS}",
                      :follow  => false,
                      :ftype => 'directory',
                      :mindepth => 3,
                      :maxdepth => 5,
                      :path    => '/opt/qa/testlogs'
                      )

hitHash = {}
now = Time.now

rule.find do |f|
  name = f.split('/').last
  unless(hitHash.key?(name))
    build = Build.find(:first, :conditions => "name ='%s'"%name)  #name collision between branch is very rare
    if(build.nil?)
      hitHash[name] = true  #not in system, delete
    elsif(build.note =~ /\w+/)
      hitHash[name] = false
    else
      hitHash[name] = build.created_on < now - (120 * 24 * 60 * 60)  # 120 days prior
    end
    if(hitHash[name])
      puts "Deleting %s"%f
      FileUtils.rm_rf(f)
    end
  end
end 
