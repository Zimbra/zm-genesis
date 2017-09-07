#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# Run script across the machines
# Tai-Sheng Hwang
#
# == Synopsis
#
# runScript: run script across the machines
#
# == Usage
#
# runScript.rb [OPTION] SCRIPT
#
# -h, --help:
#    show help
#
# --server, -s:
#   server name filter, mutliple values are allowed
#
# --verbose -v:
#   turn on the verbosity.  It is very noisy
#
# --norun -n:
#   do not issue request to the server.  Instead print out the url string
# SCRIPT: name of the script
#
module Runscript 
  
  require 'yaml'
  require 'rubygems'
  require 'activeresource'
  require 'ostruct'
  require 'getoptlong'
  require 'rdoc/usage'
  require 'net/http'
  require "pp"
  require 'uri'
  
  
  # Argument processing
  opts = GetoptLong.new(
                        
  [ '--help', '-h', GetoptLong::NO_ARGUMENT],
  [ '--server', '-s', GetoptLong::OPTIONAL_ARGUMENT],
  [ '--verbose', '-v',GetoptLong::NO_ARGUMENT],
  [ '--norun', '-n', GetoptLong::NO_ARGUMENT]
  
  )

  PTMS = ENV['tms'] || 'zqa-tms.eng.vmware.com'

  
  CONFIG = OpenStruct.new(:siteURL => 'http://%s'%PTMS, 
  :tms => "http://%s"%PTMS
   
  ) 
  
  
  MOUTFORMAT = "%10s(%s)"
  MSEP = '=' * 80
  
 
  
  class Machine < ActiveResource::Base
    def pretty_print(printer)
      printer.text((MOUTFORMAT+" queue size->%i")% [self.class.name, name, queueSize])
    end
  end
  
  
  
  def Runscript::processOption(pOpts, pConfig)
    pOpts.each do |opt, arg|
      case opt
        when '--help'
        RDoc::usage
        exit 
        when '--verbose'
        pConfig.verbose = true
        when '--norun'
        pConfig.norun = true
        when '--server'
        pConfig.server = arg  = (pConfig.branchfilter + arg.split(/[,\s]+/)) rescue arg.split(/[,\s]+/) 
      end    
    end
    pConfig.script = ARGV.shift  
    pConfig
  end
  
  def Runscript::processConfig(pConfig)
    #parse URI
    
    # Test setting should be removed
    #pConfig.verbose = true
    #pConfig.norun = true
    #pConfig.script = 'installjson.sh'
    #pConfig.siteURL = "http://localhost:3000"
    pConfig
  end 
  
  def Runscript::generateCommands(pMachine, pConfig)
    [
      "staf #{pMachine} process start workdir /tmp command '/bin/rm' parms '-f #{pConfig.script}' wait returnstdout",
      "staf #{pMachine} process start workdir /tmp command wget parms '-v #{pConfig.tms}/files/#{pConfig.script}' wait returnstdout returnstderr", 
      "staf #{pMachine} process start workdir /tmp command bash parms '-x ./#{pConfig.script}' wait returnstdout returnstderr"
    ]
  end
   
  
  processOption(opts, CONFIG) 
  processConfig(CONFIG) 
  
  puts YAML.dump(CONFIG) if CONFIG.verbose
  Machine.site = CONFIG.siteURL
  
  
  
  #
  mMachines =  
    Machine.find(:all, :from => :machinelist, :params => 
    {:conditions => "machine_type = 'Machine'", :onholdtoo => true}) # Get a list of machines, exclude machine groups
  mMachines = mMachines.select {|x| CONFIG.server.any? { |y|  (x.name+'.'+x.domain).include?(y)  } } if CONFIG.server
  
  machineFilterList = ['VMWARE', ('NT' if CONFIG.server.nil?)].compact #NT is excluded by default
   
  mMachines = mMachines.select {|x| !machineFilterList.include?(x.osName) }.map {|x| x.name+'.'+x.domain}.sort  
  puts YAML.dump(mMachines)
  puts 'Checking machines' 
  goodMachines = if(CONFIG.norun)
    mMachines
  else 
    mMachines.select do |x| 
      print x if CONFIG.verbose
      STDOUT.flush
      data = `staf #{x} ping ping`
      if(result = data.include?('PONG')) 
        puts " good" if CONFIG.verbose
      else
        puts " bad #{data}" if CONFIG.verbose
      end
      result
    end
  end
  
  badMachines = mMachines - goodMachines
  puts "Good machines #{YAML.dump(goodMachines)}"
  puts "Bad machines #{YAML.dump(badMachines)}"
  puts "Running script"
 
  ## process data
  goodMachines.each do |x| 
     mCommands = generateCommands(x, CONFIG)
     if(CONFIG.norun)
      puts YAML.dump(mCommands)
    else
      puts "running on #{x}"
      begin
      Timeout::timeout(120) do
        mCommands.each {|y| result = `#{y}`; puts result if CONFIG.verbose} 
      end 
      rescue Timeout::Error
        puts("#{x} timeout")
      end
     end
  end 
end
