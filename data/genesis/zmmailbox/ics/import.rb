#!/usr/bin/ruby -w
#
# = data/imap/search/seen.rb
#
# Copyright (c) 2010 vmware
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# ics import bug# 4579
# unlike others, this script is correct only when run locally on zimbra server
if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"
require "action/zmprov"
require "action/block"
require "action/verify"
require "action/runcommand"
require "action/zmmailbox"
require "action/zmcontrol"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "ZMMailbox ICS Import"

name = 'zmics'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)
include Action

ics = <<EOF
BEGIN:VCALENDAR
PRODID:Zimbra-Calendar-Provider
VERSION:2.0
METHOD:PUBLISH
BEGIN:VTIMEZONE
TZID:America/Los_Angeles
BEGIN:STANDARD
DTSTART:19710101T020000
TZOFFSETTO:-0800
TZOFFSETFROM:-0700
RRULE:FREQ=YEARLY;WKST=MO;INTERVAL=1;BYMONTH=11;BYDAY=1SU
TZNAME:PST
END:STANDARD
BEGIN:DAYLIGHT
DTSTART:19710101T020000
TZOFFSETTO:-0700
TZOFFSETFROM:-0800
RRULE:FREQ=YEARLY;WKST=MO;INTERVAL=1;BYMONTH=3;BYDAY=2SU
TZNAME:PDT
END:DAYLIGHT
END:VTIMEZONE
BEGIN:VEVENT
UID:58e0d182-5793-4b6c-9b6b-bd036b827109
SUMMARY:Test
DESCRIPTION:test 
X-ALT-DESC;FMTTYPE=text/html:<html><body><div style='font-family:Times New R
 oman\; font-size: 12pt\; color: #000000\;'>test</div></body></html>
ORGANIZER;CN=Demo User Two:mailto:user2@wii.zimbra.com
DTSTART;TZID="America/Los_Angeles":20100329T120000
DTEND;TZID="America/Los_Angeles":20100329T130000
STATUS:CONFIRMED
CLASS:PUBLIC
X-MICROSOFT-CDO-INTENDEDSTATUS:BUSY
TRANSP:OPAQUE
X-MICROSOFT-DISALLOW-COUNTER:TRUE
DTSTAMP:20100331T213853Z
SEQUENCE:0
X-FOOBAR;TZID="Invalid":foobar
END:VEVENT
END:VCALENDAR
EOF

 
#
# Setup
#
current.setup = []

#
# Execution
#
current.action = [
                  CreateAccount.new(testAccount.name,testAccount.password), 
                  RunCommand.new(File.join(Command::ZIMBRAPATH,'bin','zmlocalconfig'),Command::ZIMBRAUSER, '-e calendar_ics_import_full_parse_max_size=1'),
                  v(ZMControl.new('stop')) do |mcaller, data|
                    mcaller.pass = (data[0] == 0) && data[1].include?("Stopping")&& !data[1].include?("FAILED")
                  end,
                  v(ZMControl.new('start')) do |mcaller, data|
                    mcaller.pass = (data[0] == 0) && data[1].include?("Starting ")&& !data[1].include?("FAILED")
                  end,     
                  cb("Sleep 180 seconds", 240) { Kernel.sleep(180)},
                  cb("create file") do 
                    File.open("/opt/zimbra/data/tmp/checkme.ics", "w") do |file|
                      file.puts ics
                    end
                  end,
                  v(ZMailAdmin.new('-m', testAccount.name, 'pru', '/Calendar', '/opt/zimbra/data/tmp/checkme.ics')) do |mcaller, data|  
                    mcaller.pass = !data[1].split(/\n/).any?  {|x| x=~/ics formatter failure/ }
                  end
                 ]
#
# Tear Down
#
current.teardown = [     
                    DeleteAccount.new(testAccount.name)
                   ]

if($0 == __FILE__)
  require 'engine/simple'
  
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run    
end
