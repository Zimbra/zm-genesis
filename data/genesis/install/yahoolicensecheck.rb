#!/usr/bin/ruby -w
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

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model" 
require "action/block"
require "action/runcommand" 
require "action/verify"
require "action/buildparser"
#require "action/zmcontrol" 

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Y! License test"

include Action 


expectedLicense1 = ["PLEASE READ THIS AGREEMENT CAREFULLY BEFORE USING THE SOFTWARE.",
                    'ZIMBRA, INC. ("ZIMBRA") WILL ONLY LICENSE THIS SOFTWARE TO YOU IF YOU',
                    "FIRST ACCEPT THE TERMS OF THIS AGREEMENT. BY DOWNLOADING OR INSTALLING",
                    "THE SOFTWARE, OR USING THE PRODUCT, YOU ARE CONSENTING TO BE BOUND BY",
                    "THIS AGREEMENT. IF YOU DO NOT AGREE TO ALL OF THE TERMS OF THIS",
                    "AGREEMENT, THEN DO NOT DOWNLOAD, INSTALL OR USE THE PRODUCT.",
                    "",
                    "License Terms for the Zimbra Collaboration Suite:",
                    "http://www.zimbra.com/license/zimbra_public_eula_2.1.html",
                    "",
                    "",
                    "Press Return to continue"
                   ]
  
expectedLicense2 = ["# ***** BEGIN LICENSE BLOCK *****",
                    "# ",
                    "# Zimbra Collaboration Suite Server",
                    "# Copyright (C) 2004, 2005, 2006, 2007 Zimbra, Inc.",
                    "# ",
                    "# The contents of this file are subject to the Yahoo! Public License",
                    "# Version 1.0 (\"License\"); you may not use this file except in",
                    "# compliance with the License.  You may obtain a copy of the License at",
                    "# http://www.zimbra.com/license.",
                    "# ",
                    "# Software distributed under the License is distributed on an \"AS IS\"",
                    "# basis, WITHOUT WARRANTY OF ANY KIND, either express or implied.",
                    "# ",
                    "# ***** END LICENSE BLOCK *****"
                   ]

#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [       
  
  v(cb("Y! License test1") do
    mObject = BuildParser.new()
    mResult = mObject.run
    if mResult[0] != 0
      mResult
    else
      if false #mObject.targetBuildId =~ /NETWORK/
        [0, "Skipping - NETWORK version]"]
      else
        timestamp = mObject.timestamp
        mObject = Action::RunCommand.new("/bin/cat", "root", "/tmp/install.out." + timestamp)
        license = []
        mResult = mObject.run[1].split(/\n/).collect {|w| w.strip()}
        mResult.each_index do |idx|
          if mResult[idx] =~ /#{expectedLicense1[0]}/
            license = mResult[idx, expectedLicense1.length]
            break
          end
        end
        if license == expectedLicense1
          [0, 'Success']
        else
          [1, {"IS" => license, "SB" => expectedLicense1}]
        end
      end
    end
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      if data[0] == 0
        mcaller.badones = {'Y! License printed by installer' => {"IS"=>data[1], "SB"=>"Skipping..."}}
      else
        mcaller.badones = {'Y! License printed by installer' => {}}
        expectedLicense1.each_index do |i|
          if data[1]["IS"][i] != expectedLicense1[i]
            mcaller.badones['Y! License printed by installer']["line #{i}"] = {"IS"=>data[1]["IS"][i], "SB"=>expectedLicense1[i]}
          end
        end
      end
    end
  end,
  
  v(cb("Y! License test2") do
    res = []
    ['/opt/zimbra/libexec', '/opt/zimbra/bin'].each do |dir|
      mObject = Action::RunCommand.new("file", "root",
                                       "`find #{dir} -type f -print`")
      iResult = mObject.run[1]
      if(iResult =~ /Data\s+:/)
        iResult = (iResult)[/Data\s+:(.*?)\s*\}/m, 1]
      end
      iResult = iResult.select {|w| w =~ /\stext\s/}.collect {|w| w.split(/:\s+/)[0]}
      iResult.each do |cmd|
      #['/opt/zimbra/libexec/zmloggerinit','/opt/zimbra/libexec/zmqaction'].each do |cmd|
        cmd = cmd.strip.chomp
        mObject = RunCommand.new("/bin/cat", "root", cmd)
        mResult = mObject.run[1]    		 
        if(mResult =~ /Data\s+:/)
          mResult = (mResult)[/Data\s+:(.*?)\s*\}/m, 1]
        end
        license = []
        mResult = mObject.run[1].split(/\n/)#.collect {|w| w.strip()}
        mResult.each_index do |idx|
          if mResult[idx] =~ /BEGIN LICENSE BLOCK/
            license = mResult[idx, expectedLicense2.length]
            break
          end
        end
        if license == expectedLicense2
          [0, 'Success']
        else
          if license == []
            license = ["NOT FOUND"]
          end
          res << [cmd, license]
        end
      end
    end
	[0, res]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].empty?
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'Y! License test2' => {}}
      data[1].each do |crt|
        expectedLicense2.each_index do |i|
          if crt[1][i] != expectedLicense2[i]
            mcaller.badones['Y! License test2'][crt[0]] = {"IS"=>crt[1][i], "SB"=>expectedLicense2[i]}
          end
        end
      end
    end
  end,
]
    	

#
# Tear Down
#
current.teardown = [         
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end 