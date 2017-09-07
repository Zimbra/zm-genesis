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
# Limitation, currently only run local
if($0 == __FILE__)
  $:.unshift(File.join(File.dirname(__FILE__), '..'))
  #$:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end

require 'action/command'

module Action # :nodoc
  #
  #  Create TCPDump file
  #
  class TCPDump < Action::Command
    
    attr :file, true
    attr :dump, true
    attr :os, true
    attr :pidlist, true
    attr :platform_setting, true
    attr :port, true
    attr :data, true
    attr :interface, true
    
    EXTENSION = 'tcpdump'
    PLATFORM = {
      :unix => { :interface => {:internal => :lo, :external => :eth0}, :pid => 3}, 
      :osx =>  { :interface => {:internal => :lo0, :external => :en0}, :pid => 1}
    }
    #
    #Objection creation
    #port = default port
    #current_file = the file to dump to
    def initialize(port = 143, file = '/tmp/tcpdump', os = :unix)
      super()
      self.pidlist = []
      self.port = port
      self.file = file
      self.os = os
      self.platform_setting = PLATFORM[os] || raise("platform setting not found #{os}")
      self.data = nil # nothing to report back the test driver this is file dump only
      self.dump = false #this has to be explicitly set
      self.interface = :internal #hard coded for now
    end
    
    def set(env)
      { :port => :port=, :file => :file=, :os => :os=, 
        :dump => :dump=}.each do |key, method| #set few variables if exist
        self.send(method, env[key]) if env.has_key?(key)
      end
      self.platform_setting = PLATFORM[os] || raise("platform setting not found #{os}") 
      if env.has_key?(:platform_setting)
        self.platform_setting = env[:platform_setting]
      end     
    end
    
    #
    # Execute change user id action
    #  
    def run
      super()  
      true_file_name = "%s_%s_%s.%s"%[file, platform_setting[:interface][interface], port, EXTENSION]
      #start tcpdump with the file name and trap process id
      command = "(tcpdump -X -s 0 -i #{platform_setting[:interface][interface]} -w #{true_file_name} port #{port} >/dev/null 2>&1&); ps -elf | grep 'tcpdump' | egrep -v 'sh|grep|rb$'"   
      result = `#{command}`
      sleep(5) #need to wait for a bit before tcpdump is ready
      self.pidlist.push(true_file_name)
    end
    
    def fetch
      [*pidlist].each do |x|
        if(!dump)
          File.unlink(x) rescue Errno::ENOENT
        end
      end
      self.pidlist = []
      tcpdump = `which tcpdump`.chomp
      command = "fuser -k %s"%tcpdump
      puts `#{command}`
    end
    
    def to_str 
      "Action::TCPDump port #{port} file #{file}}"
    end  
  end
  
  
end

if $0 == __FILE__
  require 'test/unit'  
  
  module Action
    # Unit test cases for TCPDump
    class TCPDumpTest < Test::Unit::TestCase  
      
      def test_creation
        testObject = Action::TCPDump.new
        assert(TCPDump::EXTENSION == 'tcpdump')
        assert(testObject.file == '/tmp/tcpdump')
        assert(testObject.port == 143)
        assert(testObject.pidlist == [])
        assert(testObject.os == :unix)
        assert(testObject.platform_setting == TCPDump::PLATFORM[:unix])
      end     
 
      def test_set
        testObject = Action::TCPDump.new
        testObject.set(:port => 7143, :file => '/iam/here', :os => :unix, :dump => true)
        assert(testObject.port == 7143)
        assert(testObject.file == '/iam/here')
        assert(testObject.dump == true)
      end
      
      def test_run
        testObject = Action::TCPDump.new
        testObject.set(:port => 143, :file => '/tmp/hi')
        testObject.run
        #assert(testObject.pidlist.size > 0)
        #puts YAML.dump(testObject)
        #sleep(10)
        testObject.fetch
        true_file_name = "%s_%s_%s.%s"%['/tmp/hi', testObject.platform_setting[:interface][testObject.interface], testObject.port, TCPDump::EXTENSION]
        puts true_file_name
        assert(File.exist?(true_file_name) == false)
        testObject.set(:dump => true)
        testObject.run
        testObject.fetch
        assert(File.exist?(true_file_name) == true)
      end
    end
  end
end



