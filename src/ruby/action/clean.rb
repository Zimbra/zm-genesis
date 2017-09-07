#!/usr/bin/ruby -w
#
# = action/untar.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# Part of the command class structure.  The command will erase file from top
# level directory and downward
# 
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end
require 'action/command'
require 'action/stafsystem'
require 'action/tomcat'
require 'model/testbed'
 

module Action # :nodoc
  #
  #  Perform cleaning action
  #
  class Clean < Action::Command
    #
    # Objection creation
    # bind Clean object with specified +filename+
    def initialize(toplevel = 'zimbramail', eraseTop = false)
      super()  
      self.timeOut = 600
      
      @toplevel = toplevel
      @eraseTop = eraseTop
    end
     
    #
    # Execute Clean action
    # filename is stored inside @@filename at object initilization time 
    def run()
      super() 
      if(Model::TARGETHOST == Model::CLIENTHOST)
        packagedir = File.expand_path(@toplevel) 
        clean_one_level(packagedir, @eraseTop)     
      else
        if(not @eraseTop)
          command = "#{Action::STAF} #{Model::TARGETHOST} FS DELETE ENTRY #{@toplevel} CHILDREN RECURSE CONFIRM"
        else
          command = "#{Action::STAF} #{Model::TARGETHOST} FS DELETE ENTRY #{@toplevel}  RECURSE CONFIRM"
        end        
        IO.popen(command).close_read 
      end
    end
    
    def clean_one_level(filePath, eraseMe)
      return if not File::exist?(filePath)
      return if (File.split(filePath)[0] == '/') #not going to touch top level stuffs
      
      begin
        Dir.foreach(filePath) { |x|
          fullName = File::join(filePath, x) 
          next if x.match('^\.\.{0,1}$')
          if(File.directory?(fullName) && (not File::symlink?(fullName))) #do not follow symbolic link
            clean_one_level(fullName, true)
          else 
            begin
              File.unlink(fullName)
            rescue
            end
          end          
        }
        if(eraseMe == true)
          if(File::symlink?(filePath))
            File.unlink(filePath)
          else
            Dir.unlink(filePath)
          end
        end 
      rescue SystemCallError
      end
    end 
    
    def to_str
      "Action:Clean path:#{@toplevel}"
    end   
  end  
  
  class CleanBackup < Action::Clean
    def initialize(filePath = nil, erasetop = false)
      if(filePath)
        super(filePath, erasetop)
      else
        super(File.join(ZIMBRAPATH,"backup"), erasetop)
      end
    end
    
    def run  
      super 
    end
  end
  
  class CleanRedoLog < Action::Clean
    def initialize(filePath = nil, erasetop = false)
      if(filePath)
        super(filePath, erasetop)
      else
        super(File.join(ZIMBRAPATH, "redolog"), erasetop)
      end
    end
  end
end
if $0 == __FILE__
  require 'action/runcommand'
  require 'test/unit'
  
  module Action  
    # Unit test cases for Clean
    class CleanTest < Test::Unit::TestCase 
 
        
        def testSimple
          mDir = ['/tmp/deleteaction', '/tmp/deleteaction/hi', '/tmp/deleteaction/one.txt']
          mDir.each do |x|
            RunCommand.new('/bin/mkdir','root', x).run
          end          
          #testObject = Action::Clean.new("/tmp/deleteaction").run
          assert(RunCommand.new("/bin/env", 'root', 'file /tmp/deleteaction/hi').run[1].include?('cannot'))
          assert(RunCommand.new("/bin/env", 'root', 'file /tmp/deleteaction/one.txt').run[1].include?('cannot'))
          assert(RunCommand.new("/bin/env", 'root', 'file /tmp/deleteaction').run[1].include?('directory'))
          mDir.each do |x|
            RunCommand.new('/bin/rm', 'root',"-f %s"% x)
          end         
        end    
        
        def testEreaseTop
          mDir = ['/tmp/deleteaction', '/tmp/deleteaction/hi', '/tmp/deleteaction/one.txt']
          mDir.each do |x|
            RunCommand.new('/bin/mkdir','root', x).run
          end          
          #testObject = Action::Clean.new("/tmp/deleteaction", true).run
          mDir.each do |x|
            assert(RunCommand.new("/bin/env", 'root', "file #{x}").run[1].include?('cannot'))            
          end         
          mDir.each do |x|
            RunCommand.new('/bin/rm', 'root',"-f %s"% x)
          end         
        end   
        
        def testTOS
          testObject = Action::Clean.new
          assert(testObject.class == Action::Clean)
        end 
    end
  end
end

