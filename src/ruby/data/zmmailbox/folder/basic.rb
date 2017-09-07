#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2010 Vmware Zimbra
#
# zmmailbox folder related basic testcases

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "model"
require "action/zmmailbox"
require "action/zmprov"
require "action/verify"


#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "zmmailbox folder test"


include Action

name = File.expand_path(__FILE__).sub(/.*?(data\/)(genesis\/)?(zm)?/, 'zm').sub('.rb', '').gsub(/\/|\(|\)/, '') + Time.now.to_i.to_s
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)
adminAccount = Model::TARGETHOST.cUser('admin', Model::DEFAULTPASSWORD)

#
# Setup
#
current.setup = [
]

#
# Execution
#

current.action = [
  v(ZMailAdmin.new('help', 'folder')) do |mcaller, data|
    expected = ['createFolder\(cf\)\s+\[opts\] \{folder\-path\}',
                '-u\/\-\-url <arg>\s+url to connect to',
                '-F\/--flags <arg>\s+flags',
                '-V\/--view <arg>\s+default type for folder \(appointment,contact,conversation,document,message,task,wiki\)',
                '-c\/--color <arg>\s+color',
                'createMountpoint\(cm\)\s+\[opts\] \{folder\-path\} \{owner\-id\-or\-name\} \{remote\-item\-id\-or\-path\} \[\{reminder\-enabled \(0\*\|1\)\}\]',
                '-F\/--flags <arg>\s+flags',
                '-V\/--view <arg>\s+default type for folder \(appointment,contact,conversation,document,message,task,wiki\)',
                '-c\/--color <arg>\s+color',
                'createSearchFolder\(csf\)\s+\[opts\] \{folder\-path\} \{query\}',
                '-t\/--types <arg>\s+list of types to search for \(message,conversation,contact,appointment,document,task,wiki\)',
                '-s\/--sort <arg>\s+sort order TODO',
                '-c\/--color <arg>\s+color',
                'deleteFolder\(df\)\s+\{folder\-path\}',
                'emptyFolder\(ef\)\s+\{folder\-path\}',
                'getAllFolders\(gaf\)\s+\[opts\]',
                '-v\/--verbose\s+verbose output',
                'getFolder\(gf\)\s+\[opts\] \{folder\-path\}',
                '-v\/--verbose\s+verbose output',
                'getFolderRequest\(gfr\)\s+\[opts\] \{folder\-id\}',
                '-v\/--verbose\s+verbose output',
                'getFolderGrant\(gfg\)\s+\[opts\] \{folder\-path\}',
                '-v\/--verbose\s+verbose output',
                'importURLIntoFolder\(iuif\)\s+\{folder\-path\} \{url\}',
                'markFolderRead\(mfr\)\s+\{folder\-path\}',
                'modifyFolderChecked\(mfch\)\s+\{folder\-path\} \[0\|1\*\]',
                'modifyFolderColor\(mfc\)\s+\{folder\-path\} \{new\-color\}',
                'modifyFolderExcludeFreeBusy\(mfefb\)\s+\{folder\-path\} \[0\|1\*\]',
                'modifyFolderFlags\(mff\)\s+\{folder\-path\} \{folder\-flags\}',
                'modifyFolderGrant\(mfg\)\s+\{folder\-path\} \{account \{name\}\|group \{name\}\|cos \{name\}\|domain \{name\}\|all\|public\|guest \{email\}\|key \{email\} \[\{accesskey\}\] \{permissions\|none\}\}',
                'modifyFolderURL\(mfu\)\s+\{folder\-path\} \{url\}',
                'modifyMountpointEnableSharedReminder\(mmesr\) \{mountpoint\-path\} \{0\|1\}',
                'renameFolder\(rf\)\s+\{folder\-path\} \{new\-folder\-path\}',
                'syncFolder\(sf\)\s+\{folder\-path\}'
               ]
    mcaller.pass = data[0] == 0 &&
                   ZMMail.outputOnly(data[1]).split(/\n/).compact.delete_if{|w| w == ''}.select {|w| w !~ /#{Regexp.new(expected.join('|'))}/}.empty?
  end,

  CreateAccount.new(testAccount.name,testAccount.password),

  v(ZMailAdmin.new('-m', testAccount.name, 'mfg', '/Inbox', 'account', adminAccount.name, 'r')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,

  v(ZMailAdmin.new('-m', testAccount.name, 'gfg', '/Inbox')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('Permissions')\
                                && data[1].include?('account  %s'%adminAccount.name)
  end,

  v(ZMailAdmin.new('-m', testAccount.name, 'mfg', 'briefcase', 'cos', 'default', 'r')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,

  v(ZMailAdmin.new('-m', testAccount.name, 'gfg', 'briefcase')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('Permissions')\
                                && data[1] =~ /^\s*r\s+cos\s+default$/
  end,

   #Bug:56459
  v(ZMailAdmin.new('-m', testAccount.name, 'mfg', '/', 'account', adminAccount.name, 'rwixd')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,

  v(ZMailAdmin.new('-m', adminAccount.name, 'cm', '/Shared', testAccount.name, '/')) do |mcaller, data|
    mcaller.pass=data[0]==0 && data[1]=~ /d+/
  end,
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
