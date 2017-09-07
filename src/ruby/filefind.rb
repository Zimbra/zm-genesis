#!/usr/bin/ruby
#/bin/env /u/apps/TMS/current/script/runner   this is to bypass ruby -c failure on hudson machine
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2012 VMWare
#
# This script cleans up TMS log files
#
require 'rubygems'
require 'file/find'
require 'yaml'

#
# Process handler
#
class Handler
  def Handler.norun(x)
    puts "No run on %s"%x
  end    

  def Handler.delete(x)
    puts "%s Deleting %s"%[Time.now, x]
    `rm -r -f #{x}`
  end
end

#
# Typical testlog
#
TESTFUNCTIONAL = { 
  :pattern => "*{_FOSS,_NETWORK,_ZCA,_ZDESKTOP,_OCTOPUS}",
  :follow  => false,
  :ftype => 'directory',
  :mindepth => 3,
  :maxdepth => 3,
  :path    => '/opt/qa/testlogs',
  #those are extra configuration need to exclude those
  :age =>  7 * 30 * 24 * 60 * 60, # 7 months
  :handler => Handler.method(:delete),
  :extras => [:age, :handler]
}
#
# Coverage testlog
#
TESTCOVERAGE = {
  :pattern => "*{_FOSS,_NETWORK,_ZCA,_ZDESKTOP,_OCTOPUS}",
  :follow  => false,
  :ftype => 'directory',
  :mindepth => 3,
  :maxdepth => 3,
  :path    => '/opt/qa/testlogs/CodeCoverage/ZCS',
  #those are extra configuration need to exclude those
  :age =>  7 * 30 * 24 * 60 * 60, # 7 months
  :handler => Handler.method(:delete),
  :extras => [:age, :handler]
}

def process(configuration)

  extraKeys = (configuration[:extras] ||[]) << :extras
  filters = configuration.reject do |key, value| # get rid of extra keys
    extraKeys.include?(key)
  end

  rule =  File::Find.new(filters)
  hitHash = {}
  now = Time.now

  rule.find do |f|

    name = f.split('/').last
    unless(hitHash.key?(name))
      build = Build.find(:first, :conditions => "name ='%s'"%name)  #name collision between branch is very rare
      if(build.nil?)
        hitHash[name] = true 
      elsif(build.note =~ /\w+/)
        hitHash[name] = false
      else
        hitHash[name] = build.created_on < now - configuration[:age] 
      end
    end

    if(hitHash[name])
      yield f, true if block_given?
    else
      yield f, false if block_given?
    end
    
  end 
  hitHash
end

def trim(*directives)
  counter = 0
  directives.each do |coverage|
    process(coverage) do |file, hit|
      counter += 1
      if(hit)
        coverage[:handler].call(file)
      else
        puts "%s %s %s"%[Time.now, counter, file] if (counter%1000 == 1)
      end
    end
  end
end

trim(TESTCOVERAGE, TESTFUNCTIONAL)



