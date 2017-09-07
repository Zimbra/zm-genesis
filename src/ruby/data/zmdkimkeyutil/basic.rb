#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2012 Vmware Zimbra
#
# Basic test zmdkimkeyutil
#

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require 'model'
require 'action'
require "action/zmdkimkeyutil"

include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Basic test zmdkimkeyutil"

timeStamp = File.expand_path(__FILE__).sub(/.*?(data\/)(genesis\/)?(zm)?/, 'zm').sub('.rb', '').gsub(/\/|\(|\)/, '') + Time.now.to_i.to_s
domain1 = timeStamp + '1.org'
domain2 = timeStamp + "2.org"

# not supported keys
not_supported = (0..9).to_a + ('a'..'z').to_a + ('A'..'Z').to_a - %w"a b d h q r s u" - %w"a b d q r s u".map { |x| x.upcase }
not_supported << ['--start', "-i -d #{Model::TARGETHOST}"]

usage =  [Regexp.escape('Usage: /opt/zimbra/libexec/zmdkimkeyutil [-a [-b]] [-q] [-r] [-s selector] [-S] [-u [-b]] [-d domain]'),
          Regexp.escape('-a: Add new key pair and selector for domain'),
          Regexp.escape("-b: Optional parameter specifying the number of bits for the new key"),
          Regexp.escape('Only works with -a and -u.  Default when not specified is 2048 bits.'),
          Regexp.escape('-d domain: Domain to use'),
          Regexp.escape('-h: Show this usage block'),
          Regexp.escape('-q: Query DKIM information for domain'),
          Regexp.escape('-r: Remove DKIM keys for domain'),
          Regexp.escape('-s: Use custom selector string instead of random UUID'),
          Regexp.escape('-S: Generate keys with subdomain data.  This must be used if you want to sign both example.com and sub.example.com separately.'),
          Regexp.escape('Only works with -a and -u.  Default is not to set this flag.'),
          Regexp.escape('-u: Update keys for domain'),
          Regexp.escape('One of [a, q, r, or u] must be supplied'),
          Regexp.escape('For -q, search can be either by selector or domain'),
          Regexp.escape('For all other usage patterns, domain is required')
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

  # help message
  ['-h', '', '--help'].map do |x|
    v(ZMDkimkeyutil.new(x)) do |mcaller,data|
      mcaller.pass = data[0] != 0 &&
                     (lines = data[1].split(/\n/).select {|w| w !~ /^\s*$/}).size == usage.size &&
                     lines.select {|w| w !~ /#{usage.join('|')}/}.empty?
    end
  end,
  
  # not known command
  ['stop', 'start', '123', 'please do something'].map do |x|
    v(ZMDkimkeyutil.new(x)) do |mcaller,data|
      mcaller.pass = data[0] != 0 &&
                     (lines = data[1].split(/\n/).select {|w| w !~ /^\s*$/}).size == usage.size &&
                     lines.select {|w| w !~ /#{usage.join('|')}/}.empty?      
    end
  end,
    
  # not known key
  not_supported.map do |x|
    v(ZMDkimkeyutil.new(x)) do |mcaller,data|
      lines = data[1].split(/\n/).select {|w| w !~ /^\s*$/}
      mcaller.pass = data[0] != 0 &&
                     lines.select {|w| w !~ /#{usage.join('|')}|#{Regexp.escape('Unknown option:')}/}.empty?  
    end
  end,
    
  # test dkim key uniqueness
  v(ZMProv.new('cd', domain1)) do |mcaller,data|
    mcaller.pass = data[0] == 0 && data[1].chomp =~ /[0-9a-f\-]{36}/  
  end,

  v(ZMProv.new('cd', domain2)) do |mcaller,data|
    mcaller.pass = data[0] == 0 && data[1].chomp =~ /[0-9a-f\-]{36}/  
  end,
    
  v(ZMDkimkeyutil.new('-a', '-d', domain1, '-s', mKey = 'testKey' + timeStamp)) do |mcaller,data|
    mcaller.pass = data[0] == 0 && data[1] =~ /DKIM Data added to LDAP for domain #{domain1} with selector #{mKey}\n/
  end,
    
  v(ZMDkimkeyutil.new('-a', '-d', domain2, '-s', mKey)) do |mcaller,data|
    mcaller.pass = data[0] != 0 && data[1] =~ /Error: Failed to update LDAP: Selector #{mKey} is already in use/
  end
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

