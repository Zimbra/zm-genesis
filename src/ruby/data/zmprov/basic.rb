#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2006 Zimbra
#
# zmprov basic test

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "model"
require "action/zmprov"
require "action/verify"
require "action/block"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Zmprov Basic test"


include Action

#
# Setup
#
current.setup = [

]

#
# Execution
#
current.action = [
  #Help
  v(ZMProv.new('?')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('Try')
  end,
  
  v(ZMProv.new('help')) do |mcaller, data|
    usage = [Regexp.escape('usage:  flushCache(fc) [-a] ' +
                           '{acl|locale|skin|uistrings|license|all|account|config|globalgrant|cos|domain|galgroup|group|' +
                           'mime|server|alwaysOnCluster|zimlet|<extension-cache-type>} [name1|id1 [name2|id2...]]'),
             Regexp.escape('zmprov [args] [cmd] [cmd-args ...]'),
             Regexp.escape('-h/--help                             display usage'),
             Regexp.escape('-f/--file                             use file as input stream'),
             Regexp.escape('-s/--server   {host}[:{port}]         server hostname and optional port'),
             Regexp.escape('-l/--ldap                             provision via LDAP instead of SOAP'),
             Regexp.escape('-L/--logpropertyfile                  log4j property file, valid only with -l'),
             Regexp.escape('-a/--account  {name}                  account name to auth as'),
             Regexp.escape('-p/--password {pass}                  password for account'),
             Regexp.escape('-P/--passfile {file}                  read password from file'),
             Regexp.escape('-z/--zadmin                           use zimbra admin name/password from localconfig for admin/password'),
             Regexp.escape('-y/--authtoken {authtoken}            use auth token string (has to be in JSON format) from command line'),
             Regexp.escape('-Y/--authtokenfile {authtoken file}   read auth token (has to be in JSON format) from a file'),
             Regexp.escape('-v/--verbose                          verbose mode (dumps full exception stack trace)'),
             Regexp.escape('-d/--debug                            debug mode (dumps SOAP messages)'),
             Regexp.escape('-m/--master                           use LDAP master (only valid with -l)'),
             Regexp.escape('-r/--replace                          allow replacement of safe-guarded multi-valued attributes configured ' +
                           'in localconfig key "zmprov_safeguarded_attrs"'),
             Regexp.escape('zmprov is used for provisioning. Try:'),
             Regexp.escape('zmprov help account         help on account-related commands'),
             Regexp.escape('zmprov help calendar        help on calendar resource-related commands'),
             Regexp.escape('zmprov help commands        help on all commands'),
             Regexp.escape('zmprov help config          help on config-related commands'),
             Regexp.escape('zmprov help cos             help on COS-related commands'),
             Regexp.escape('zmprov help domain          help on domain-related commands'),
             Regexp.escape('zmprov help freebusy        help on free/busy-related commands'),
             Regexp.escape('zmprov help list            help on distribution list-related commands'),
             Regexp.escape('zmprov help log             help on logging commands'),
             Regexp.escape('zmprov help misc            help on misc commands'),
             Regexp.escape('zmprov help mailbox         help on mailbox-related commands'),
             Regexp.escape('zmprov help reverseproxy    help on reverse proxy related commands'),
             Regexp.escape('zmprov help right           help on right-related commands'),
             Regexp.escape('zmprov help search          help on search-related commands'),
             Regexp.escape('zmprov help server          help on server-related commands'),
             Regexp.escape('zmprov help alwaysoncluster help on alwaysOnCluster-related commands'),
             Regexp.escape('zmprov help ucservice       help on ucservice-related commands'),
             Regexp.escape('zmprov help share           help on share related commands'),
            ]
    mcaller.pass = data[0] == 0 &&
                   data[1].split(/\n/).select {|w| w !~ /(#{usage.join('|')}|^$)/}.empty?
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
  Engine::Simple.new(Model::TestCase.instance, true).run
end