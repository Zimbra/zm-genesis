#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2007 Zimbra
# Check for errors in zmsetup/install log:
# - zmprov errors: usage:  modifyServer(ms) {name|id} [attr1 value1 [attr2 value2...]]
#                  zmprov [args] [cmd] [cmd-args ...]
# - gibberish messages
# - ldapmodify: modify operation type is missing at line


if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
mypath = 'data'
if($0 =~ /data\/genesis/)
  mypath += '/genesis'
end

require "model" 
require "action/block"
require "action/runcommand" 
require "action/verify"
require "#{mypath}/install/historyparser"
require "#{mypath}/install/utils"
require "action/zmlocalconfig"
require "action/buildparser"
require "#{mypath}/install/configparser"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Install errors detection test"

include Action 

log = 'NOTFOUND'
mKeystore = ZMLocal.new('mailboxd_keystore').run
mKeystore = '/opt/zimbra/mailboxd/etc/keystore' if mKeystore =~ /Warning: null valued key/

errors = ['^usage:\s+.*',
          'Segmentation fault.*',
          '[\x0-\x8\xb\xc\xe-\x1f\x7f].*',
          'ldapmodify:\s+modify operation type is missing at line .*',
          '^BEGIN failed--compilation aborted.*',
          '^ERROR: service.INVALID_REQUEST \(invalid request.*',
          '^ERROR\s+\d+\s+\(\w{5}\)',
          'ssh-keygen:\s+.*:\s+no version information available',
          'ERROR: account.INVALID_ATTR_NAME.*',
          'ulimit: open files: cannot modify limit: Invalid argument',
          'Key for ' + Model::TARGETHOST + ' NOT FOUND',
          'cp: cannot stat .*(keystore|\/cron\/.*\/zimbra).: No such file or directory',
          'ch(own|mod): cannot access .*: No such file or directory',
          'chown: (too few arguments|missing operand after)',
          'sed: .* unknown command:',
          'hdiutil:\s+.*failed',
          '^error\s+',
          '^Exception in thread\s+',
          '[sS]yntax error(\s+on line .*)?:.*',
          'slapadd: could not parse entry',
          'Zimlet \S+ being installed is of an older version',
          'Cannot add or update a child row: a foreign key constraint fails\s+.*',
          'sh:\s+\S+: command not found',
          '-(su|bash): line \d+:.*command not found',
          'Undefined subroutine &\S+(::\S+)* called at',
          "Can't locate .* in @INC",
          '.*: line \d+:.*missing `.*',
          "amavis.*DIE",
          "Unable to find expected .*\.\s+Found version .* instead",
          '.*invalid value for attributeType\s+.*',
          "/opt/zimbra/.*: No such file or directory",
          "Do you want to verify logger database integrity\?",
          "su: invalid option --",
          "ERROR: Invalid schedule:",
          "unary operator expected",
          "warning: not owned by root: /opt/zimbra",
          'com\.zimbra\.\S+Exception: zimbra\S+ value length\(\d+\) larger then max allowed: \d+',
          'zimlet - Unable to load zimlet handler for com_zimbra_.*$',
          '.*Unable to create temp file.*',
          "#{mKeystore} didn't exist.",
          'line \d+: syntax error',
          'error:[0-9A-F]+:PEM routines:',
          'ERROR: uninstall expected to delete zimbra startup script',
          'Error: No default configuration found',
          'Setting up syslog.conf\.{3}Failed',
          'df: no file systems processed',
          'Attempt to modify a deprecated attribute.*$',
          'Received new license from tms',
          '.*system failure: unable to modify attrs: LDAP error',
          'com.mysql.jdbc.exceptions.jdbc4.MySQLSyntaxErrorException: Table\s+.*',
          'Unknown option:',
          'Unable to restart \S*syslog\S* service.  Please do it manually.',
          'slapadd import failed',
          'Unknown config type \S+ for key.*',
          "java.util.MissingResourceException: Can't find resource for bundle java.util.PropertyResourceBundle",
          '.*Exception:\s+.*',
          '.+segfault.+',
          'error: Missing argument for option',
          'SSL connect attempt failed with unknown error',
         ]
         
(history = HistoryParser.new).run
(mCfg = ConfigParser.new).run
isRelease = RunCommand.new('ls', 'root', File.join(Command::ZIMBRAPATH, '.uninstall', 'packages', 'zimbra-core*')).run[1] =~ /GA/

errors << 'This is a Network Edition .* build and is not intended for production.' if isRelease

excepts = ['^ERROR: service.INVALID_REQUEST \(invalid request:\s+port\s+(110|993|143|995).*',
           'hdiutil: detach failed - No such file or directory',
           'error reading information on service (ccsd|cman|fenced|rgmanager): No such file or directory',
          ]
excepts << 'com.zimbra.cs.account.AccountServiceException: zimbraMtaRestriction value length\(\d+\) larger than max allowed: \d+'
excepts << 'warning: not owned by root: /opt/zimbra(/data)?/postfix'
excepts << "#{mKeystore} didn't exist." if !Utils::isUpgrade()
excepts << "192.168.1.0/24': -c: line 1: syntax error: unexpected end of file" if Utils::isAppliance
excepts << '.*\[74G\[ OK \]' if Utils::isAppliance
#excepts << 'df: no file systems processed'  if history.targetVersion =~ /(7|8)\.(1|0)\.\d_(RC1|GA)/
excepts << 'Attempt to modify a deprecated attribute:\s+zimbraInstalledSkin' if !isRelease
excepts << 'kernel: .* opendkim\[\d+\]: segfault at 1f0' if BuildParser.instance.targetBuildId =~ /IRONMAIDEN-D(4|5)/ || Utils::isUpgradeFrom('8.0.0.GA')

startTime = DateTime.new
def getStartTime(log)
  mObject = Action::RunCommand.new('/usr/bin/head', 'root', '-1', log)
  data = mObject.run
  iResult = data[1]
  if(iResult =~ /Data\s+:/)
    iResult = (iResult)[/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
  end
  startTime = DateTime.parse(iResult)
end
#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [       
  v(RunCommand.new("/bin/ls", 'root', '-rt1',
                   '/opt/zimbra/log/zmsetup.*.txt')) do |mcaller, data|
    iResult = data[1]
    if data[0] == 0
      if(iResult =~ /Data\s+:/)
        iResult = (iResult)[/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
      end
      iResult = iResult.split("\n")[-1]
      log = iResult
    end
    mcaller.pass = data[0] == 0 && log != 'NOTFOUND'
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'zmsetup log retrieval' => {"IS"=>log, "SB"=>"Found"}}
    end
  end,
  
  v(cb("Zmsetup errors detection test") do
    res = []
    mObject = Action::RunCommand.new('/bin/cat', 'root', log)
    data = mObject.run
    iResult = data[1]
    if(iResult =~ /Data\s+:/)
      iResult = (iResult)[/Data\s+:\s+([^\s}].*?)$\s*\}/m, 1]
    end
    if data[0] == 0
      #msgs = iResult.select {|w| w =~ /Regexp.compile(errors.join('|'))/}
      res = Hash[*iResult.gsub(/\n\t+/m, "\t").gsub(/\n(Caused by:\s+)/m, '\t\1').split(/\n/).select {|w| w =~ /#{Regexp.compile(errors.join('|'))}/}.select {|w| w !~ /#{Regexp.compile(excepts.join('|'))}/}.collect {|w| [w.chomp, 1]}.flatten]
    else
      res = [iResult]
    end
    [data[0], res]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].empty?
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {log + ' errors check' => {}}
      data[1].keys.each_index do |i|
        mcaller.badones[log + ' errors check']["error #{i + 1}"] = {"IS"=>data[1].keys[i], "SB"=>"No error"}
      end
    end
  end,
  
  v(cb("install log retrieval") do
    if Utils::isAppliance
      log = 'APPLIANCE'
      next [0, log]
    end
    mResult = RunCommand.new("/bin/ls", 'root', '-rt1', '/tmp/install.out.*').run
    iResult = mResult[1]
    if mResult[0] == 0
      if(iResult =~ /Data\s+:/)
        iResult = (iResult)[/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
      end
      iResult = iResult.split("\n")[-1]
      log = iResult
    end
    mResult
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && log != 'NOTFOUND'
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'install log retrieval' => {"IS"=>log, "SB"=>"Found"}}
    end
  end,
  
  v(cb("Install errors detection test") do
    res = []
    next [0, []] if Utils::isAppliance
    mObject = Action::RunCommand.new('/bin/cat', 'root', log)
    data = mObject.run
    iResult = data[1]
    if(iResult =~ /Data\s+:/)
      iResult = (iResult)[/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
    end
    if data[0] == 0
      #msgs = iResult.select {|w| w =~ /Regexp.compile(errors.join('|'))/}
      res = iResult.split(/\n/).select {|w| w =~ /#{Regexp.compile(errors.join('|'))}/}.select {|w| w !~ /#{Regexp.compile(excepts.join('|'))}/}.collect {|w| w.strip.chomp}.uniq
    else
      res = [iResult]
    end
    [data[0], res]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].empty?
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {log + ' errors check' => {"IS"=>data[1].join("\n"), "SB"=>"No error"}}
    end
  end,
  
  v(RunCommand.new("/bin/ls", 'root', '-rt1',
                   '/opt/zimbra/log/zmsetup.*.txt')) do |mcaller, data|
    iResult = data[1]
    if data[0] == 0
      if(iResult =~ /Data\s+:/)
        iResult = (iResult)[/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
      end
      iResult = iResult.split("\n")[-1]
      log = iResult
    end
    mcaller.pass = data[0] == 0 && log != 'NOTFOUND'
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'zmsetup log retrieval' => {"IS"=>log, "SB"=>"Found"}}
    end
  end,
  
  v(cb("/var/log/zimbra.log errors detection test") do
    res = []
    startTime = getStartTime(log)
    mObject = Action::RunCommand.new('/bin/cat', 'root', '/var/log/zimbra.log')
    data = mObject.run
    iResult = data[1]
    if(iResult =~ /Data\s+:/)
      iResult = (iResult)[/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
    end
    if data[0] == 0
      res = iResult.split(/\n/).select {|w| w =~ /#{Regexp.compile(errors.join('|'))}/}.select {|w| w !~ /#{Regexp.compile(excepts.join('|'))}/}.collect {|w| w.chomp}
      #retain only errors after startTime (i.e upgrade only errors on upgrades)
      res = res.select  do |w|
        begin
          DateTime.parse(w) >= startTime
        rescue
          DateTime.parse(w[/^(.*\d+(:\d+){2})/, 1] + " " + startTime.year().to_s) >= startTime
        end
      end

    else
      res = [iResult]
    end
    [data[0], res]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].empty?
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'/var/log/zimbra.log errors check' => {"IS"=>data[1], "SB"=>"No error"}}
    end
  end,
  
  v(cb("install.log errors detection test") do
    next [0, []] if Utils::isAppliance
    stamp = history.timestamp
    if history.platform =~ /MACOSX/i
      next ([0, []])
    end
    mResult = RunCommand.new("/bin/ls", 'root', '-rt1', '/tmp/install.log.*').run
    next(mResult) if mResult[0] != 0
    if(mResult[1] =~ /Data\s+:/)
      mResult[1] = (mResult[1])[/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
    end
    log = mResult[1].split("\n")[-1]
    res = []
    mObject = Action::RunCommand.new('/bin/cat', 'root', log)
    data = mObject.run
    iResult = data[1]
    if(iResult =~ /Data\s+:/)
      iResult = (iResult)[/Data\s+:\s+([^\s}].*?)$\s*\}/m, 1]
    end
    if data[0] == 0
      res = []
      iResult.split("\n").reverse.each do |w|
        res.push(w)
        break if w =~ /zimbra-core.*#{stamp}/
      end
      res = Hash[*res.reverse.select {|w| w =~ /#{Regexp.compile(errors.join('|'))}/}.select {|w| w !~ /#{Regexp.compile(excepts.join('|'))}/}.collect {|w| [w.chomp, 1]}.flatten]
    else
      res = [iResult]
    end
    [data[0], res]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].empty?
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {log + ' errors check' => {}}
      data[1].keys.each_index do |i|
        mcaller.badones[log + ' errors check']["error #{i + 1}"] = {"IS"=>data[1].keys[i], "SB"=>"No error"}
      end
    end
  end,
  
  mCfg.getServersRunning('store').map do |x|
    v(cb("mailbox errors detection test") do
      res = []
      mObject = Action::RunCommandOn.new(x, '/bin/cat', 'root', File.join(Command::ZIMBRAPATH, 'log', 'mailbox.log'))
      data = mObject.run
      iResult = data[1]
      if(iResult =~ /Data\s+:/)
        iResult = (iResult)[/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
      end
      if data[0] == 0
        crt = startTime
        res = iResult.split(/\n/).select  do |w|
          (crt = DateTime.parse(w) rescue crt) >= startTime
        end
        res = res.select {|w| w =~ /#{Regexp.compile(errors.join('|'))}/}.select {|w| w !~ /#{Regexp.compile(excepts.join('|'))}/}.collect {|w| w.strip.chomp}
      else
        res = [iResult]
      end
      [data[0], res.collect{|w| w[/(#{Regexp.compile(errors.join('|'))})/, 1]}.uniq]
    end) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1].empty?
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {File.join(Command::ZIMBRAPATH, 'log', 'mailbox.log') + ' errors check' => {"IS"=>data[1].join("\n"), "SB"=>"No error"}}
      end
    end
  end,
  
  v(cb("Appliance postinstall errors detection test") do
    res = []
    next [0, res] if !Utils::isAppliance
    if Utils::isAppliance
      errors << 'ERROR: account.NO_SUCH_ACCOUNT'
      errors << 'com.zimbra.common.service.ServiceException:\s+system failure'
    end
    mObject = Action::RunCommand.new('/bin/cat', 'root',
                                     File.join(File::SEPARATOR, 'opt', 'zcs-installer', 'log', 'appliance_postinstall.log'))
    data = mObject.run
    iResult = data[1]
    if(iResult =~ /Data\s+:/)
      iResult = (iResult)[/Data\s+:\s+([^\s}].*?)$\s*\}/m, 1]
    end
    if data[0] == 0
      #puts iResult.split(/\n/).select {|w| w =~ /#{Regexp.compile(errors.join('|'))}/}
      res = Hash[*iResult.gsub(/\n\t+/m, "\t").gsub(/\n(Caused by:\s+)/m, '\t\1').split(/\n/).select {|w| w =~ /#{Regexp.compile(errors.join('|'))}/}.select {|w| w !~ /#{Regexp.compile(excepts.join('|'))}/}.collect {|w| [w.chomp, 1]}.flatten]
    else
      res = [iResult]
    end
    [data[0], res]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].empty?
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'Appliance postinstall errors check' => {}}
      data[1].keys.each_index do |i|
        mcaller.badones['Appliance postinstall errors check']["error #{i + 1}"] = {"IS"=>data[1].keys[i], "SB"=>"No error"}
      end
    end
  end,
  
  v(cb("zmconfigd errors detection test") do
    res = []
    mObject = Action::RunCommand.new('/bin/cat', 'root', File.join(Command::ZIMBRAPATH, 'log', 'zmconfigd.log'))
    data = mObject.run
    iResult = data[1]
    if(iResult =~ /Data\s+:/)
      iResult = (iResult)[/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
    end
    if data[0] == 0
      res = iResult.split(/\n/).select {|w| w =~ /#{Regexp.compile(errors.join('|'))}/}.select {|w| w !~ /#{Regexp.compile(excepts.join('|'))}/}.collect {|w| w[/(#{Regexp.compile(errors.join('|'))})/, 1]}.uniq
    else
      res = [iResult]
    end
    [data[0], res]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].empty?
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'zmconfigd.log errors check' => {"IS"=>data[1].join("\n"), "SB"=>"No error"}}
    end
  end,
  
  v(cb("/var/log/messages errors detection test") do
    res = []
    mResult = Action::RunCommand.new('/bin/cat', 'root', File.join('/var', 'log', 'messages')).run
    next mResult if mResult[0] != 0
    res = mResult[1].split(/\n/).select {|w| w =~ /#{Regexp.compile(errors.join('|'))}/}.select {|w| w !~ /#{Regexp.compile(excepts.join('|'))}/}.uniq#.collect {|w| w[/(#{Regexp.compile(errors.join('|'))})/, 1]}.uniq
    res = res.select  do |w|
      month = DateTime.parse(w[/^(.*\d+(:\d+){2})/, 1] + " " + startTime.year().to_s).month
      if month >= startTime.month || (month == 1 && startTime.month == 12)
        DateTime.parse(w[/^(.*\d+(:\d+){2})/, 1] + " " + startTime.year().to_s) >= startTime
      end
    end
    [mResult[0], res]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].empty?
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'/var/log/messages errors check' => {"IS"=>data[1].join("\n"), "SB"=>"No error"}}
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
