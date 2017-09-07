#!/usr/bin/ruby -w
#
# = action/zmmailbox.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# Part of the command class structure.  This is the interface to zmprov command
#
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end
require 'action/runcommand' 
require 'tempfile'
require 'model/testbed'
require 'json'

module Action # :nodoc
  module ZMMailHelper
    def ZMMailHelper.deleteItems(account, kind = 'message') #message,conversation,contact,appointment,document,task'
      mResult = ZMailAdmin.new('-m', account, 'search', '-t', kind, '"*"').run
      count = mResult[1][/^num:\s+(\d+),/, 1]
      return [0, 0] if count == '0'
      ids = mResult[1].split(/\n/).select {|w| w =~ /^\d+\.\s+\d+\s+#{kind[0, 3]}/}.collect {|w| w[/\.\s+(\d+)/, 1]}
      mResult = ZMailAdmin.new('-m', account, 'moveItem', ids.join(','), '/Trash').run
      return [0, ids.length] if mResult[0] == 0 #&&messages empty
      [mResult[0], ZMMail.outputOnly(mResult[1])]
    end
    
    def ZMMailHelper.deleteItemsFromTrash(account, kind = 'message') #message,conversation,contact,appointment,document,task'
      mResult = ZMailAdmin.new('-m', account, 'search', '-t', kind, 'in:trash').run
      count = mResult[1][/^num:\s+(\d+),/, 1]
      return [0, 0] if count == '0'
      ids = mResult[1].split(/\n/).select {|w| w =~ /^\d+\.\s+\d+\s+#{kind[0, 3]}/}.collect {|w| w[/\.\s+(\d+)/, 1]}
      mResult = ZMailAdmin.new('-m', account, 'deleteItem', ids.join(',')).run
      return [0, ids.length] if mResult[0] == 0 #&&messages empty
      [mResult[0], ZMMail.outputOnly(mResult[1])]
    end
    
    def ZMMailHelper.recoverToFolder(account, kind = 'message', folder = '/inbox') #conversation,contact,appointment,document,task
      mResult = ZMailAdmin.new('-m', account, 'search', '-t', kind, '--dumpster', "\"*\"").run
      count = mResult[1][/^num:\s+(\d+),/, 1]
      return [0, 0] if count == '0'
      ids = mResult[1].split(/\n/).select {|w| w =~ /^\d+\.\s+\d+\s+#{kind[0, 3]}/}.collect {|w| w[/\.\s+(\d+)/, 1]}
      mResult = ZMailAdmin.new('-m', account, 'recoverItem', ids.join(','), folder).run
      return [0, ids.length] if mResult[0] == 0 #&&messages empty
      [mResult[0], ZMMail.outputOnly(mResult[1])]
    end
    # simple implementation
    def ZMMailHelper.getFolderId(account, name)
      mCmd = ['-z', '-m', account.name, 'gaf', '-v']
      mResult = RunCommandOnMailbox.new('zmmailbox', Command::ZIMBRAUSER, mCmd).run
      return 'UNDEF' if mResult[0] != 0
      begin
        folders = JSON::parse(mResult[1])
        return folders['id'] if name == '/'
        folders['subFolders'].select {|w| w['path'] == name}.first['id']
      rescue
        'UNDEF'
      end
    end
  end #end module
  #
  # Perform zmmail action.  This will invoke some zmprov with some argument
  # from http server
  #
  class ZMMail < Action::RunCommandOnMailbox
    @@soapReceiveEnd = '=+\s+\(\d+\s+msecs\)'
    #
    #  Create a ZMMail object.
    #    
    def initialize(*arguments)
      super(File.join(ZIMBRAPATH,'bin','zmmailbox'), ZIMBRAUSER, '-d', '-v', *arguments)           
    end 
    
    def ZMMail.outputOnly(res, delimiter = @@soapReceiveEnd)
      res[/.*#{delimiter}(.*)/m, 1].strip rescue nil
    end
  end 
  
  class ZMailAdmin < ZMMail
    def initialize(*arguments)    
      super('-z', *arguments)
    end
  end
end

if $0 == __FILE__
  require 'test/unit'
  module Action
    #
    # Unit test case for ZMProv object
    class ZMMailTest < Test::Unit::TestCase
      def testHelp
          testObject = ZMMail.new('-h')
          puts YAML.dump(testObject.run)
      end      
    end
  end
end
