#!/bin./env ruby
#
# = hsm/basic.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# Cronjob basic test
# 

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path  
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby'))
end 
 
require "model"
require "action/block"
require "action/runcommand" 
require "action/verify"


#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Cronjob Basic Test"

 
include Action

verificationMatrix = [
'SHELL=/bin/bash',
'30 2 * * * find /opt/zimbra/log/ ! -name \'zmsetup*.log\' -type f -name \'*.log?*\' -mtime +8 -exec rm {} \; > /dev/null 2>&1',
'*/2 * * * * /opt/zimbra/libexec/zmstatuslog',
#'*/10 * * * * /opt/zimbra/libexec/zmdisklog',
'30 2 * * * find /opt/zimbra/mailboxd/logs/ -type f -name \*log\* -mtime +8 -exec rm {} \; > /dev/null 2>&1',
'0 23 * * 7 /opt/zimbra/libexec/zmdbintegrityreport -m',
'*/5 * * * * /opt/zimbra/libexec/zmcheckduplicatemysqld -e > /dev/null 2>&1',
'00,10,20,30,40,50 * * * * /opt/zimbra/libexec/zmlogprocess > /tmp/logprocess.out 2>&1',
#'10 * * * * /opt/zimbra/libexec/zmgengraphs >> /tmp/gengraphs.out 2>&1',
'30 23 * * * /opt/zimbra/libexec/zmdailyreport -m',
'0,10,20,30,40,50 * * * * /opt/zimbra/libexec/zmqueuelog',
'0 22 * * * /opt/zimbra/bin/zmtrainsa >> /opt/zimbra/log/spamtrain.log 2>&1',
'45 23 * * * /opt/zimbra/bin/zmtrainsa --cleanup >> /opt/zimbra/log/spamtrain.log 2>&1',
'20 23 * * * /opt/zimbra/common/bin/sa-learn --dbpath /opt/zimbra/data/amavisd/.spamassassin --force-expire --sync > /dev/null 2>&1 ',
'15 5,20 * * * find /opt/zimbra/data/amavisd/tmp -maxdepth 1 -type d -name \'amavis-*\' -mtime +1 -exec rm -rf {} \; > /dev/null 2>&1',
'35 2 * * * find /opt/zimbra/log/ -type f -name \'*.out.????????????\' -mtime +8 -exec rm {} \; > /dev/null 2>&1',
'50 2 * * * /opt/zimbra/libexec/zmcompresslogs > /dev/null 2>&1',
'40 2 * * * /opt/zimbra/libexec/zmcleantmp',
'*/2 * * * * /opt/zimbra/libexec/zmstatuslog > /dev/null 2>&1',
'0 0 1 * * /opt/zimbra/libexec/zmcheckexpiredcerts -days 30 -email',
'*/30 * * * * /opt/zimbra/libexec/zmldapmonitordb > /dev/null 2>&1',
'30 2 * * * find /opt/zimbra/log/ -type f -name stacktrace.\* -mtime +8 -exec rm {} \; > /dev/null 2>&1',
'18 */2 * * * /opt/zimbra/libexec/zmcheckversion -c >> /dev/null 2>&1',
"15 2 * * *\t/opt/zimbra/libexec/zmcomputequotausage > /dev/null 2>&1",
"55 1 * * *\t/opt/zimbra/libexec/client_usage_report.py > /dev/null 2>&1",
"49 0 * * 7\t/opt/zimbra/libexec/zmgsaupdate > /dev/null 2>&1",
'45 0 * * * . /opt/zimbra/.bashrc; /opt/zimbra/libexec/zmsaupdate',
'0 1 * * * find /opt/zimbra/data/amavisd/quarantine -type f -mtime +7 -exec rm -f {} \; > /dev/null 2>&1',
'35 3 * * * /opt/zimbra/bin/zmcbpadmin --cleanup >/dev/null 2>&1',
'0 1 * * 6 /opt/zimbra/bin/zmbackup -f -a all --mail-report',
'0 1 * * 0-5 /opt/zimbra/bin/zmbackup -i --mail-report',
'0 0 * * * /opt/zimbra/bin/zmbackup -del 1m --mail-report'
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
  v(RunCommand.new('crontab','zimbra', '-l')) do |mcaller, data|     
    class << mcaller
      attr :failures, true
    end
    mcaller.failures = []
    verificationMatrix.map do |x|
       unless data[1].include?(x) 
          mcaller.failures.push({:expected => x}) 
       end
    end
    data[1].split(/\n/).select {|w| w !~ /^#.*/}.select {|w| w !~ /^$/}.map do |x|
       unless verificationMatrix.include?(x) 
          mcaller.failures.push({:unexpected => x}) 
       end
    end
    mcaller.pass = (mcaller.failures.size == 0)   
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
