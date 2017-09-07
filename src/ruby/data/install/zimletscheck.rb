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

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 

mypath = 'data'
if($0 =~ /data\/genesis/)
  mypath += '/genesis'
end

#require 'json'
require "model" 
require "action/block"
require "action/runcommand" 
require "action/verify"
require "fileutils" 
require "action/zmprov"
require "#{mypath}/install/utils"
require "#{mypath}/install/configparser"
require 'action/buildparser'

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Zimlets test"

include Action 


@suffix = "notdef"
#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

ldapUrl = "UNDEF"
ldapPass = "UNDEF"
ldapZimlets = {}
expectedZimlets = ['UNDEF']
#webserverSkipZimlets = ['com_zimbra_search']
(mCfg = ConfigParser.new).run

current.action = [       

  v(RunCommand.new(File.join(Command::ZIMBRAPATH,'bin','zmlocalconfig'), Command::ZIMBRAUSER,
                              '-s', '-m nokey', 'ldap_url')) do |mcaller, data|
    data[0] = 1 if data[1] =~ /Warning: null valued key/
    ldapUrl = data[1]
    if(ldapUrl =~ /Data\s+:/)
      ldapUrl = ldapUrl[/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
    end
    ldapUrl.chomp!
    mcaller.pass = data[0] == 0
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'ldap_url' => {"IS"=>ldapUrl, "SB"=>"Defined"}}
    end
  end,
  
  v(RunCommand.new(File.join(Command::ZIMBRAPATH,'bin','zmlocalconfig'), Command::ZIMBRAUSER,
                              '-s', '-m nokey', 'zimbra_ldap_password')) do |mcaller, data|
    data[0] = 1 if data[1] =~ /Warning: null valued key/
    ldapPass = data[1]
    if(ldapPass =~ /Data\s+:/)
      ldapPass = ldapPass[/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
    end
    ldapPass.chomp!
    mcaller.pass = data[0] == 0
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'zimbra_ldap_password' => {"IS"=>ldapPass, "SB"=>"Defined"}}
    end
  end,
  
  v(cb("ldap_zimlets") do
    mObject = RunCommand.new(File.join(Command::ZIMBRACOMMON,'bin','ldapsearch'), Command::ZIMBRAUSER,
                   '-H', ldapUrl.split.first,
                   '-x', 
                   '-w', ldapPass,
                   '-D', 'uid=zimbra,cn=admins,cn=zimbra',
                   '-b', 'cn=zimlets,cn=zimbra',
                   'objectClass=zimbraZimletEntry',
                   'cn', 'zimbraZimletIsExtension')
                   # | grep "cn: " | awk '{print $2}'`
    #ldapZimlets = mObject.run[1]
    data = mObject.run
    if data[0] == 0
      mResult = data[1]
      if(mResult =~ /Data\s+:/)
        mResult = mResult[/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
      end
      start = 0
      key = nil
      val = nil
      mResult.split(/\n/).each do |line|
        if line =~ /^$/ # && !val.nil?
          ldapZimlets[key] = val if !key.nil?
          key = nil
          val = nil
          next
        end
        val = line[/zimbraZimletIsExtension:\s+(\S+)/, 1] if line =~ /^zimbraZimletIsExtension:/
        key = line[/cn:\s+(\S+)/, 1] if line =~ /^cn:/
      end
    end
    [data[0], ldapZimlets]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'ldap_zimlets' => {"IS"=>ldapZimlets.keys.join(" "), "SB"=>"Defined"}}
    end
  end,
  
  mCfg.getServersRunning('store').map do |x|
  [
    v(cb("expected_zimlets") do
      mResult = RunCommand.new("/bin/ls", "root", '-1', '/opt/zimbra/zimlets/', '2>&1', host = Model::Host.new(x)).run
      next mResult[0..1] << 'zimlets in /opt/zimbra/zimlets' if mResult[0] != 0
      expectedZimlets = mResult[1].split(/\n/).collect {|w| File.basename(w.chomp, ".zip")}
      if BuildParser.instance.targetBuildId =~ /NETWORK/i
        mResult = RunCommand.new("/bin/ls", "root", '-1', '/opt/zimbra/zimlets-network/', '2>&1', host).run
        next mResult[0..1] << 'zimlets in /opt/zimbra/zimlets-network' if mResult[0] != 0
        expectedZimlets += mResult[1].split(/\n/).select {|w| w =~ /\.zip/}.collect {|w| File.basename(w.chomp, ".zip")}
      end
      next [1, 'com_zimbra_cluster', 'missing'] if expectedZimlets.include?('com_zimbra_cluster')
      expectedZimlets.push('com_zimbra_viewmail').uniq
      #expect xmailer zimlet on upgrade
      expectedZimlets.push('com_zimbra_xmailer').uniq if Utils::isUpgrade
      expectedZimlets = expectedZimlets + ['com_zimbra_click2call_cisco', 'com_zimbra_click2call_mitel', 'com_zimbra_voiceprefs'] if Utils::isUpgrade
      [0, expectedZimlets, '']
    end) do |mcaller, data|
      mcaller.pass = data[0] == 0
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {x + ' - expected_zimlets' => {"IS" => data[1], "SB" => data[2]}}
      end
    end,
#  end,
  
#  mCfg.getServersRunning('store').map do |x|
    v(cb("zimbraZimletIsExtension check", 300) do
      exitCode = 0
      res = {}
      ldapZimlets.each_pair do |k, v|
        next if k =~ /_(archive|xmbxsearch)/ && !mCfg.getServersRunning('mta').include?(x)
        is = v.downcase rescue v
        mResult = RunCommand.new('cat', 'root', File.join(Command::ZIMBRAPATH, 'zimlets-deployed', k, k + '.xml'), Model::Host.new(x)).run
        if mResult[0] != 0
          res[k] = mResult[1]
          exitCode += 1
        else
          sb = Document.new(mResult[1]).root.attributes['extension']
          expected = sb.nil? ? 'false' : sb 
          existing = is.nil? ? 'false' : is
          res[k] = {'IS' => v.nil? ? 'nil' : v, 'SB' => sb.nil? ? 'nil' : sb} if existing != expected
        end
      end
      [exitCode, res]
    end) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1].empty?
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {x + ' - LDAP attribute zimbraZimletIsExtension' => data[1]}
      end
    end,

    v(cb("webserver_ldap_zimlets") do
      skipZimlets = mCfg.getServersRunning('mta').include?(x) ? [] : ['com_zimbra_archive', 'com_zimbra_xmbxsearch']
      #skipZimlets = Utils::isUpgrade() && (Utils::isUpgradeFrom('5\.0.\d+') || Utils::isUpgradeFrom('6\.0\.[0-6]_')) ? ['com_zimbra_local'] : []
      #skipZimlets.push('com_zimbra_ymemoticons') if Utils::isUpgrade() && (Utils::isUpgradeFrom('7\.0\.0_BETA[12]') || Utils::isUpgradeFrom('6\.0\.\d+') || Utils::isUpgradeFrom('5\.0\.\d+'))
      mObject = RunCommand.new("/bin/ls", "root", '-1',
                             File.join(Command::ZIMBRAPATH, 'zimlets-deployed'), Model::Host.new(x))
      data = mObject.run
      mResult = data[1]
      if(mResult =~ /Data\s+:/)
        mResult = mResult[/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
      end
      webserverZimlets = mResult.split(/\n/).collect {|w| w.chomp} - skipZimlets
      webserverOnly = webserverZimlets - expectedZimlets
      webserverMissing = expectedZimlets - webserverZimlets
      ldapOnly = ldapZimlets.keys - expectedZimlets - skipZimlets
      ldapMissing = expectedZimlets - ldapZimlets.keys
      mResult = [0, []]
      if !webserverOnly.empty?
        mResult[1] << ["zimlets found only in webserver", webserverOnly.join(" "), "Deleted"]
        mResult[0] += 1
      end
      if !webserverMissing.empty?
        mResult[1] << ["zimlets missing from webserver", webserverMissing.join(" "), "Installed"]
        mResult[0] += 1
      end
      if !ldapOnly.empty?
        mResult[1] << ["zimlets found only in ldap", ldapOnly.join(" "), "Deleted"]
        mResult[0] += 1
      end
      if !ldapMissing.empty?
        mResult[1] << ["zimlets missing from ldap", ldapMissing.join(" "), "Installed"]
        mResult[0] += 1
      end
      mResult
    end) do |mcaller, data|
      mcaller.pass = data[0] == 0
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {x + ' - Zimlets check' => {}}
        data[1].each do |item|
          mcaller.badones[x + ' - Zimlets check'][item[0]] = {"IS"=>item[1], "SB"=>item[2]}
        end
      end
    end,

    ((res = RunCommand.new('ls', 'root', '-1', File.join(Command::ZIMBRAPATH, 'zimlets-deployed'), Model::Host.new(x)).run)[0] == 0 ? res[1].split(/\n/) : []).map do |z|
      v(cb("zimlets content check") do
        files = RunCommand.new('find', 'root', File.join(Command::ZIMBRAPATH, 'zimlets-deployed', z, '*'),
                               '-type f -print -exec ls -l {} \;', h = Model::Host.new(x)).run[1]
        deployed = Hash[*files.split(/\n/).collect{|w| toks = w.split; [File.basename(toks.last), toks[4]]}.flatten]
        files = (res = RunCommand.new('unzip', 'root', '-l', File.join(Model::DATAPATH, 'Zimlets', z + '.zip'), h).run)[0] == 0 ? res[1].split(/\n/) : nil
        files = ((res = RunCommand.new('unzip', 'root', '-l', File.join(Command::ZIMBRAPATH, 'zimlets-network', z + '.zip'), h).run)[0] == 0 ? res[1].split(/\n/) : nil) if files.nil?
        files = ((res = RunCommand.new('unzip', 'root', '-l', File.join(Command::ZIMBRAPATH, 'zimlets', z + '.zip'), h).run)[0] == 0 ? res[1].split(/\n/) : [z + '.zip: not found']) if files.nil?
        files = files.select {|w| w !~ /.*\/$/}
        if files.length > 3
          expected = Hash[*files.slice(3..files.size-3).collect {|w| toks = w.split; [File.basename(toks.last), toks.first]}.flatten]
        else
          expected = files
        end
        [deployed, expected]
      end) do |mcaller, data|
        mcaller.pass = data[0].delete_if{|k,v| k =~ /template.js/} == data[1].delete_if{|k,v| k =~ /template.js/}
      end
    end,
  ]
  end,

  v(cb("webserver_zimlets_old") do
    mObject = RunCommand.new(File.join(Command::ZIMBRAPATH,'bin','zmlocalconfig'), Command::ZIMBRAUSER,
                             '-m nokey', 'mailboxd_server')
    iResult = mObject.run
    if iResult[1] !~ /Warning: null valued key/
      mResult = iResult[1]
      if(mResult =~ /Data\s+:/)
        mResult = mResult[/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
      end
      mResult.chomp!
    else
      mResult = 'tomcat'
    end
    mObject = RunCommand.new("/bin/ls", "root", '-1',
                             File.join(Command::ZIMBRAPATH, mResult, 'webapps/service/zimlet'))
    data = mObject.run
    if(data[1] =~ /Data\s+:/)
      data[1] = data[1][/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
    end
    data
  end) do |mcaller, data|
    mcaller.pass = data[0] != 0 && data[1] =~ /No such file or directory/
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'Old zimlets location check' => {"SB" => 'exitCode=1, No such file or directory', "IS" => "exitCode=#{data[0]}, #{data[1]}"}}
    end
  end,
    
  v(cb("zimlets name check") do [0, ldapZimlets.keys] end) do |mcaller, data|
    zimletNaming = %r/com_zimbra_[0-9A-Za-z\-_]+/
    mcaller.pass = data[0] == 0 && data[1].select {|z| z !~ zimletNaming}.empty?
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      errs = {}
      data[1].select {|z| z !~ zimletNaming}.each do |z|
        errs[z] = {"IS" => z, "SB" => zimletNaming.source}
      end
      mcaller.badones = {'zimlets name check' => errs}
    end
  end,
  
  #standard zimlets check
  v(cb("standard zimlets check") do
    mFile = 'StdZimlets'
    jDumper = 'import java.util.Set;\n' +
              'import java.util.Iterator;\n' +
              'import com.zimbra.cs.account.ldap.upgrade.BUG_76427;\n' +
              'public class StdZimlets {\n' +
              '  public static void main(String [] args) {\n' +
              '    BUG_76427 op = new BUG_76427();\n' +
              '    Set<String> standardZimlets = op.standardZimlets;\n' +
              '    Iterator<String> i = standardZimlets.iterator();\n' +
              '    while (i.hasNext()) {\n' +
              '      System.out.println(i.next());\n' +
              '    };\n' +
              '  };\n' +
              '}'
    RunCommand.new('/bin/rm', 'root', '-rf', File::join('', 'tmp', "#{mFile}.*")).run
    RunCommand.new('echo', Command::ZIMBRAUSER, '-e', "\"#{jDumper}\" > #{File::join('', 'tmp', mFile)}.java").run
    RunCommand.new('cd /tmp; javac', Command::ZIMBRAUSER, 
                   '-cp',
                   File.join(Command::ZIMBRAPATH, 'lib', 'jars', 'zimbrastore.jar'),
                   "#{mFile}.java").run
    mResult = RunCommand.new('zmjava ', Command::ZIMBRAUSER, 
                             '-cp', File::join('', 'tmp') + ':' + File.join(Command::ZIMBRAPATH, 'lib', 'jars', 'zimbrastore.jar'), mFile).run
    expectedZimlets = mResult[1].split(/\n/)
    #xmailer zimlet is disabled only on major upgrades 
    expectedZimlets.push('com_zimbra_xmailer').uniq if Utils::upgradeHistory.collect{|w| w[/(zimbra-core[-_](7|8\.0))\./, 1]}.compact.size == 0
    expectedZimlets.push('com_zimbra_mailarchive') #bug 12679 9.0.x
    expectedZimlets.push('com_zimbra_linkedinimage')
    [mResult[0], expectedZimlets]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].empty?
  end,
  
  #check all globalconfig
  v(RunCommand.new(File.join(Command::ZIMBRAPATH,'bin','zmprov'), Command::ZIMBRAUSER,
                              'gcf', 'zimbraZimletDomainAvailableZimlets')) do |mcaller, data|
    mcaller.pass = ((nonStd = data[1].split(/\n/).select {|w| w !~ /^#/}.collect {|w| w.split[1]}).select {|w| w !~ /^-/}.collect {|w| w[/^.(.*)/, 1]} - expectedZimlets).empty?
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'non-standard globalconfig zimlets' => {"IS"=>nonStd.join(" "), "SB"=>"Disabled"}}
    end
  end,
  
  #check all domains
  ZMProv.new('gad').run[1].split(/\n/).map do |x|
    v(RunCommand.new(File.join(Command::ZIMBRAPATH,'bin','zmprov'), Command::ZIMBRAUSER,
                                'gd', x, 'zimbraZimletDomainAvailableZimlets')) do |mcaller, data|
      mcaller.pass = ((nonStd = data[1].split(/\n/).select {|w| w !~ /^#/}.collect {|w| w.split[1]}).select {|w| w !~ /^-/}.collect {|w| w[/^.(.*)/, 1]} - expectedZimlets).empty?
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {'non-standard domain zimlets' => {"IS"=>nonStd.join(" "), "SB"=>"Disabled"}}
      end
    end
  end,
  
  #check all cos's
  ZMProv.new('gac').run[1].split(/\n/).map do |x|
    v(RunCommand.new(File.join(Command::ZIMBRAPATH,'bin','zmprov'), Command::ZIMBRAUSER,
                                'gc', x, 'zimbraZimletAvailableZimlets')) do |mcaller, data|
      #expect xmailer disabled on major upgrades
      expectedZimlets.delete('com_zimbra_xmailer') if Utils::upgradeHistory.collect{|w| w[/(zimbra-core[-_]7)\./, 1]}.compact.size == 1
      mcaller.pass = data[0] == 0 &&
                     (nonStd = data[1].split(/\n/).select {|w| w !~ /^#/}.collect {|w| w.split[1]}.select {|w| w !~ /^-/}.collect {|w| w[/^.(.*)/, 1]} - expectedZimlets).empty?
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {"non-standard cos #{x} zimlets" => {"IS"=>nonStd.join(" "), "SB"=>"Disabled"}}
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
