#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# Generate upgrade tests
# Tai-Sheng Hwang
#
# Copyright (c) 2006 zimbra
# == Synopsis
#
# genUpgradeTest: generate upgrade test matrix
#
# == Usage
#
# getnUpgradeTest.rb [OPTION] TARGETBRANCH
#
# -h, --help:
#    show help
#
# --basebranch -b
#   basebranch to start the test from.  If this is not supplied the value will be pulled from tms
#
# --label, -l
#    run upgrade tests against the label.  This overrides TARGETBRANCH argument
#
# --build -u:
#    run upgrade tests against the build.  This overides TARGETBRANCH argument
#
# --branchfilter -r:
#    run from this branch only.  Multiple arguments are accepted.  The argument can be specified using multiple -rs or comma sepearted.
#    For exampl,e both -r foo -r fee and -r foo,fee are acceptable.
#
# --fromlabel -f:
#    run from label only.  Multiple argments are accepted.
#
# --os -o:
#   filter upgrade selection by operation system
#
# --server, -s:
#   server name filter
#
# --targetbranch, -t:
#   target branch name
#
# --verbose -v:
#   turn on the verbosity.  It is very noisy
#
# --norun -n:
#   do not issue request to the server.  Instead print out the url string
#
# --old -q:
#   use tms instead of zqa-tms
#
# TARGETBRANCH: the branch where the upgrade test should run against.  If targetbranch is not supplied, it uses TMS latestbranch as target branch
#
# This requires activeresource-2.1.0.  However that library needs to be patched manually
#
# /var/lib/gems/1.8/gems/activeresource-2.1.0/lib/active_resource/base.rb:583:in `instantiate_collection': undefined method `collect!' for #<Hash:0x7fd5ecf83d00> (NoMethodError)
#
# from
#        def instantiate_collection(collection, prefix_options = {})
#          collection.collect! { |record| instantiate_record(record, prefix_options) }
#        end
# to
# 
#           def instantiate_collection(collection, prefix_options = {})
#          return [] if collection.nil?
#          if collection.is_a?(Hash) && collection.size == 1
#            value = collection.values.first
#            if value.is_a?(Array)
#              value.collect! { |record| instantiate_record(record, prefix_options) }
#            else
#              [ instantiate_record(value, prefix_options) ]
#             end
#           else
#             collection.collect! { |record| instantiate_record(record, prefix_options) }
#           end
#         end


module Upgrade 
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
  [ '--label', '-l', GetoptLong::OPTIONAL_ARGUMENT],
  [ '--build', '-u', GetoptLong::OPTIONAL_ARGUMENT],
  [ '--os', '-o', GetoptLong::OPTIONAL_ARGUMENT],
  [ '--verbose', '-v',GetoptLong::NO_ARGUMENT],
  [ '--norun', '-n', GetoptLong::NO_ARGUMENT],
  [ '--basebranch', '-b', GetoptLong::OPTIONAL_ARGUMENT],
  [ '--server', '-s', GetoptLong::OPTIONAL_ARGUMENT],
  [ '--branchfilter', '-r', GetoptLong::OPTIONAL_ARGUMENT],
  [ '--fromlabel', '-f', GetoptLong::OPTIONAL_ARGUMENT],
  [ '--targetbranch', '-t', GetoptLong::REQUIRED_ARGUMENT],
  [ '--old', '-q', GetoptLong::NO_ARGUMENT]
  
  )

  CONFIG = OpenStruct.new(:siteURL => 'http://zqa-tms.eng.vmware.com',  #URL for the rest request
  :tms => "http://zqa-tms.eng.vmware.com", #URL for the request generation
  :jobweight => 5 #weight of the job for each request
  ) 
  
  
  MOUTFORMAT = "%10s(%s)"
  MSEP = '=' * 80
  
  class Architecture < ActiveResource::Base
    #self.site = siteURL
    #patch http://dev.rubyonrails.org/attachment/ticket/8798/8798-patch.txt  
    def getMachines(pMachines = [])
      pMachines.select {|x| x.architecture_id == self.id}
    end
    
    def pretty_print(printer)
      printer.text MOUTFORMAT% [self.class.name, name]
    end
  end
  
  class Branch < ActiveResource::Base
    #self.site = siteURL 
    def pretty_print(printer)
      printer.text MOUTFORMAT% [self.class.name, name]
    end
  end
  
  class Machine < ActiveResource::Base
    def pretty_print(printer)
      printer.text((MOUTFORMAT+" queue size->%i")% [self.class.name, name, queueSize])
    end
  end
  
  class Build < ActiveResource::Base
    self.element_name = 'rest_build'
     #self.site = siteURL 
    def pretty_print(printer)
      printer.text((MOUTFORMAT+ " id->%5i,label->%s")% [self.class.name, name, id, note])
    end
  end 
  
  def Upgrade::processOption(pOpts, pConfig)
    pOpts.each do |opt, arg|
      case opt
        when '--help'
        RDoc::usage
        exit
        when '--label'
        pConfig.label = arg  
        when '--build'
        pConfig.build = arg 
        when '--os'
        pConfig.os = arg
        when '--verbose'
        pConfig.verbose = true
        when '--basebranch'
        pConfig.baseBranch = arg  
        when '--norun'
        pConfig.norun = true
        when '--server'
        pConfig.server = arg 
        when '--branchfilter'
        pConfig.branchfilter = (pConfig.branchfilter + arg.split(/[,\s]+/)) rescue arg.split(/[,\s]+/)
        when '--fromlabel'
        pConfig.fromlabel = (pConfig.fromlabel + arg.split(/[,\s]+/)) rescue arg.split(/[,\s]+/)
        when '--targetbranch'
        pConfig.targetBranch = arg
        when '--old'
        pConfig.tms = 'http://tms.lab.zimbra.com'
        pConfig.siteURL= 'http://tms.lab.zimbra.com'
      end
    end  
    
    pConfig
  end
  
  def Upgrade::processConfig(pConfig)
    #parse URI
    pConfig.url = URI.parse(pConfig.tms)
    pConfig.commandrun = 0
    pConfig.commandnorun = 0
    pConfig.commanderror = 0
    
    # Test setting should be removed
#    pConfig.verbose = true
#    pConfig.norun = true
#    pConfig.baseBranch = 'FRANKLIN-508'
#    pConfig.os = 'RHEL4' 
#    pConfig.branchfilter = 'FRANKLIN-509'
#    pConfig.server = 'qa03'
    pConfig
  end
  
  def Upgrade::printSummary(pConfig)
    puts
    puts "Summary"
    puts '%s' % MSEP
    puts "Run   :" + pConfig.commandrun.to_s
    puts "No Run:" + pConfig.commandnorun.to_s
    puts "Error :" + pConfig.commanderror.to_s
  end
  
  
  #Get Label Builds on a particular architecture, branch
  def Upgrade::getBuilds(pArchitecture, pBranch, pLabel = nil, pFrom = nil, pUseFilter = true, pBuild = nil)
    pFrom ||= :getbuildbyarch
    mParams = {:archID => pArchitecture.to_param, :branchID => pBranch.to_param}
    mParams[:label] = pLabel unless pLabel.nil?
    mParams[:build] = pBuild unless pBuild.nil?
    mParams[:usefilter] = pUseFilter  
    Build.find(:all, :from => pFrom, :params => mParams)
  end
  
  # Get target builds
  def Upgrade::getTargetBuilds(pArchitecture, pBranch, pLabel = nil, pBuild = nil)
    if pLabel #has label use that to fetch
      mResult = getBuilds(pArchitecture, pBranch, pLabel, nil, false, pBuild)
    else #just fetch the latest builds
      mResult = getBuilds(pArchitecture, pBranch, pLabel, :getlatestbuilds, false, pBuild)
    end  
    mResult
  end
  
  def Upgrade::selectMatchingBuild(pBuildList, pBuild)
    match = pBuild.name[/FOSS|NETWORK/] 
    pBuildList.find {|x| x.name.include?(match)}
  end
  
  #Run request
  def Upgrade::generateRequest(pOS, pBranch, pTargetMachine, pBaseBuild, pTargetBuild)  
    mRequest = '/builds/route?redirect_to=top&build=%s&branch_id=%s&os_id=%s&machine_id=%s&commit=%s&target_build_id=%s'
    mParams = [pBaseBuild.to_param, pBranch.to_param, pOS.to_param, pTargetMachine.name, 'Upgrade', pTargetBuild.to_param ].map do |x|
      URI.escape(x)
    end #make it cgi safe
    #mRequest = mRequest%[pBaseBuild.to_param, pBranch.to_param, pOS.to_param, pTargetMachine.to_param, 'Upgrade', pTargetBuild.to_param ]
    mRequest = mRequest%mParams
    mRequest << '&OSS=yes' if pBaseBuild.name[/OSS/] 
    mRequest
  end
  
  def Upgrade::getBaseBranches(basebranch, targetbuild)
    #apply branch filter if available
    rawBranches = Branch.find(:all, :from => :listfilter, :params => { :targetBranch => CONFIG.targetBranch, 
                                :firstBranch => CONFIG.baseBranch})
    CONFIG.branchfilter ? rawBranches.select {|x| [*CONFIG.branchfilter].any? {|y| y == x.name } } : rawBranches
  end
  
  processOption(opts, CONFIG) 
  processConfig(CONFIG) 
  
  if(CONFIG.targetBranch.nil?)
    puts "Target branch has to be specified with --targetbranch option"
    exit -1
  end
  
  
  Architecture.site = Branch.site = Machine.site = Build.site = CONFIG.siteURL
  
  if CONFIG.verbose
    puts "\nConfigurations\n%s" % MSEP
    pp CONFIG
  end   
  
  ##List of operating systems 
  mOS = Architecture.find(:all, :from => :listfilter) 
  mOS = mOS.select {|x| (CONFIG.os.upcase == x.name.upcase) rescue false } if CONFIG.os
  if CONFIG.verbose
    puts "\nOS\n%s"% MSEP
    pp mOS
  end
   
  ##List of branches
  mBranch = Branch.find(:all, :from => :listfilter, :params => {:targetBranch => CONFIG.targetBranch, 
    :firstBranch => CONFIG.baseBranch}) 
  
  ## IF targetBranch is not defined, it is not supplied by the user.  Use the latest one
  CONFIG.targetBranch = mBranch.max {|a, b| a.created_on <=> b.created_on }.name unless CONFIG.targetBranch
  
  ## Find the targetbranch object system can not proceed without target branch so exception is intentional here
  #CONFIG.targetBranchObject = mBranch.select {|x| x.name == CONFIG.targetBranch}.first 
  CONFIG.targetBranchObject = Branch.find(:all, 
    :params => {:conditions => "name = '#{CONFIG.targetBranch.upcase}' or name = '#{CONFIG.targetBranch.downcase}'"}).first
    
  # No target branch..exit and die
  if (CONFIG.targetBranchObject.nil?)
    puts "No target branch found"
    exit
  end

  if(mOS.size == 0)
    puts "No operating system(s) to work on. Invalid OS filter? %s"%CONFIG.os
    exit
  end
  mConditions = "architecture_id in ("+mOS.map {|x| x.to_param }.join(', ')+")"
  mConditions << " and automation = TRUE" unless CONFIG.server 

  
  ## Get a list of machines.. 
  mMachines = Machine.find(:all, :from => :machinelist, 
    :params => {:conditions => mConditions})  
    
  # Filter out the machine if Confi.server exists
  mMachines = mMachines.select do |x| 
    if(CONFIG.server.include?('.'))
      [x.name, x.domain].join('.') == CONFIG.server
    else
      x.name == CONFIG.server
    end
  end if CONFIG.server
  if CONFIG.verbose
    puts "\nMachines\n%s"% MSEP
    pp mMachines
  end  
  
  # Main processing loop
  mOS.each do |x|
    # For each architecture there is a target build; find it
    mTargetBuilds = getTargetBuilds(x, CONFIG.targetBranchObject, CONFIG.label, CONFIG.build) 
    if CONFIG.verbose
      puts "\nTarget Builds(%s)\n%s"% [x.name, MSEP]
      pp mTargetBuilds
    end
    if mTargetBuilds.size == 0
      puts "Skip target build doesn't exist"
      next
    end
    next if mTargetBuilds.size == 0
    ##pp mTargetBuilds if CONFIG.verbose 
    
    nBranch = getBaseBranches(CONFIG.targetBranchObject, [*mTargetBuilds].first) #always pick first oen of targetbuild, small bug here since it may not be matching
    if CONFIG.verbose
      puts "\nBase Branches for OS %s\n%s"% [x.name, MSEP]
      pp nBranch
      puts "\nTarget Branch for OS %s\n%s" % [x.name, MSEP]
      pp CONFIG.targetBranchObject
    end 
    nBranch.each do |y|
      mBaseBuilds = getBuilds(x, y) 
      ## Apply base build label filter if it exists
      mBaseBuilds = CONFIG.fromlabel ? mBaseBuilds.select {|xyx | [*CONFIG.fromlabel].any? {|xyy| xyy.upcase == xyx.note.upcase}} : mBaseBuilds
      if CONFIG.verbose
        puts "\nBase Builds(%s, %s)\n%s"%[x.name, y.name, MSEP]
        pp mBaseBuilds
      end 
      mBaseBuilds.each do |z|
        doGenerate = true  
        #Pick a machine pick the one with smallest queue 
        mTargetMachine = mMachines.select {|w| w.architecture_id == x.to_param.to_i}.min {|a, b| a.queueSize <=> b.queueSize} 
        # If there is no machine, no point going through the list
        
        if(mTargetMachine.nil?)
          p "Skipping #{x.name} #{y.name}, no machine" if CONFIG.verbose
          next
        end 
        # Pick the target build
        tempTarget = selectMatchingBuild(mTargetBuilds, z)
        
        # If there is no target, do nothing. If base and target is the same, do nothing
        doGenerate = false unless (tempTarget && tempTarget.to_param != z.to_param)
        # If base and target is the same, do nothing
        
        outputString = "os #{x.name} bit #{z.name[/FOSS|NETWORK/i]} base #{z.note rescue z.name}" 
        outputString << " target #{tempTarget.name rescue 'none'}"
        if(doGenerate)
          p mTargetMachine.name + " is selected for #{outputString}" if CONFIG.verbose
          currentRequest = generateRequest(x, y, mTargetMachine, z, tempTarget)
          p currentRequest if (CONFIG.verbose || CONFIG.norun) 
          # Run the request
          if(!CONFIG.norun)
            res = Net::HTTP.start(CONFIG.url.host, CONFIG.url.port) do |http|
              http.post(currentRequest, {})
            end 
            case res
              when Net::HTTPSuccess, Net::HTTPRedirection
              # OK
              CONFIG.commandrun = CONFIG.commandrun + 1
            else
              p res.error!
              CONFIG.commanderror = CONFIG.commanderror + 1
            end
          else
             CONFIG.commandnorun = CONFIG.commandnorun + 1
          end
          #Peg machine for the job queue
          mTargetMachine.queueSize = mTargetMachine.queueSize + CONFIG.jobweight unless mTargetMachine.nil? 
        else
          p "test is skipped for #{outputString} " if CONFIG.verbose
          CONFIG.commandnorun = CONFIG.commandnorun + 1
        end
      end
    end
  end
  
  printSummary(CONFIG)
end
