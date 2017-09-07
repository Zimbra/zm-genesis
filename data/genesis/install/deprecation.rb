#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2011 VMWare, Inc.
#
#

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
require "action/zmprov"
require "action/verify"
require 'rexml/document'
include REXML

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "deprecated attributes setup"

include Action
include Model

ignore = ['zimbraInstalledSkin']
def zimbraAttributes
  mResult = RunCommand.new('cat', 'root', File.join(Command::ZIMBRAPATH, 'conf', 'attrs', 'zimbra-attrs.xml')).run
  return nil if mResult[0] != 0
  iResult = mResult[1]
  Document.new iResult.slice(iResult.index('<?xml version'), iResult.index('</attrs>') - iResult.index('<?xml version') + '</attrs>'.length)
end
deprecated = []
areas = {}
 
#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [
  v(cb("deprecated attributes retrieval") do
    attributes = zimbraAttributes
    #next if attributes.nil?
    attributes.elements.each("/attrs/attr") do  |attr|
      deprecated.push(attr) if !attr.attributes["deprecatedSince"].nil? && !ignore.include?(attr.attributes['name'])
    end
    deprecated.each do |attr|
      areas[attr.attributes["requiredIn"]] = 1 if !attr.attributes["requiredIn"].nil?
      areas[attr.attributes["optionalIn"]] = 1 if !attr.attributes["optionalIn"].nil?
    end
    #puts areas.keys.sort.join("\n")
    deprecated
  end) do |mcaller, data|
    mcaller.pass = !data.nil?
  end,
  
  v(cb("deprecated globalconfig attributes deletion") do
    mAttrs = []
    deprecated.each do  |attr|
      mAttrs.push(attr.attributes['name']) if attr.attributes['requiredIn'] =~/globalConfig/
      mAttrs.push(attr.attributes['name']) if attr.attributes['optionalIn'] =~/globalConfig/
    end
    mResult = ZMProv.new('gacf', mAttrs.join(" ")).run
    next mResult if (mResult[0] != 0) || mResult[1].split(/\n/).select{ |w| w =~ /\S+:\s+\S+/}.empty?
    #TODO: attribute values may need to be passed as quoted strings
    mDelete = *mResult[1].split(/\n/).collect {|w| "-#{w}".strip.split(/:\s+/, 2)}.flatten.join(" ")
    #puts "zmprov mcf #{mDelete}"
    #puts "zmprov mcf #{mDelete.gsub('-', '+')}"
    mResult = ZMProv.new('mcf', mDelete).run
    mResult
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  
  v(cb("deprecated server attributes deletion") do
    mAttrs = []
    deprecated.each do  |attr|
      mAttrs.push(attr.attributes['name']) if attr.attributes['requiredIn'] =~ /server/
      mAttrs.push(attr.attributes['name']) if attr.attributes['optionalIn'] =~ /server/
    end
    exitCode = 0
    res = {}
    mServers = ZMProv.new('gas').run[1].split(/\n/)
    mServers.each do |server|
      mResult = ZMProv.new('gs', server, mAttrs.join(" ")).run
      next if (mResult[0] != 0) || mResult[1].split(/\n/).select{ |w| w =~ /\S+:\s+\S+/}.empty?
      mDelete = *mResult[1].split(/\n/).select {|w| w =~ /\S+:\s+\S+/}.collect {|w| "-#{w}".strip.split(/:\s+/, 2)}.flatten.join(" ")
      #puts "zmprov ms #{server} #{mDelete}"
      #puts "zmprov ms #{server} #{mDelete.gsub('-', '+')}"
      mResult = ZMProv.new('ms', server, mDelete).run
      if mResult[0] != 0
        exitCode +=1
        res[server] = mResult[1]
      end
    end
    [exitCode, res]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  
  v(cb("deprecated cos attributes deletion") do
    mAttrs = []
    deprecated.each do  |attr|
      mAttrs.push(attr.attributes['name']) if attr.attributes['requiredIn'] =~ /cos/
      mAttrs.push(attr.attributes['name']) if attr.attributes['optionalIn'] =~ /cos/
    end
    exitCode = 0
    res = {}
    mCoses = ZMProv.new('gac').run[1].split(/\n/)
    mCoses.each do |cos|
      mResult = ZMProv.new('gc', cos, mAttrs.join(" ")).run
      next if (mResult[0] != 0) || mResult[1].split(/\n/).select{ |w| w =~ /\S+:\s+\S+/}.empty?
      mDelete = *mResult[1].split(/\n/).select {|w| w =~ /\S+:\s+\S+/}.collect {|w| "-#{w}".strip.split(/:\s+/, 2)}.flatten.join(" ")
      #puts "zmprov mc #{cos} #{mDelete}"
      #puts "zmprov mc #{cos} #{mDelete.gsub('-', '+')}"
      mResult = ZMProv.new('mc', cos, mDelete).run
      if mResult[0] != 0
        exitCode +=1
        res[cos] = mResult[1]
      end
    end
    [exitCode, res]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  
  v(cb("deprecated account attributes deletion") do
    mAttrs = []
    deprecated.each do  |attr|
      mAttrs.push(attr.attributes['name']) if attr.attributes['requiredIn'] =~ /account/
      mAttrs.push(attr.attributes['name']) if attr.attributes['optionalIn'] =~ /account/
    end
    exitCode = 0
    res = {}
    mAccounts = ZMProv.new('-l', 'gaa').run[1].split(/\n/)
    mAccounts = ['admin']
    mAccounts.each do |acct|
      mResult = ZMProv.new('ga', acct, mAttrs.join(" ")).run
      next if (mResult[0] != 0) || mResult[1].split(/\n/).select{ |w| w =~ /\S+:\s+\S+/}.empty?
      mDelete = *mResult[1].split(/\n/).select {|w| w =~ /\S+:\s+\S+/}.collect {|w| "-#{w}".strip.split(/:\s+/, 2)}.flatten.join(" ")
      #puts "zmprov ma #{acct} #{mDelete}"
      #puts "zmprov ma #{acct} #{mDelete.gsub('-', '+')}"
      mResult = ZMProv.new('ma', acct, mDelete).run
      if mResult[0] != 0
        exitCode +=1
        res[acct] = mResult[1]
      end
    end
    [exitCode, res]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0
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