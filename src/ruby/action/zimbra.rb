#!/usr/bin/ruby -w
#
# Manage configuration for ruby system installation
#
#
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end

require 'action/command' 
require 'model/testbed'

require 'tempfile'
require 'socket'


module Action # :nodoc 
  class Zimbra < Action::Command
    def initialize( fileName = nil, domainName = nil)
      super()   
      @fileName = fileName
      @domainName = domainName
      @TemplateName = Model::QA04
    end
    
    def fetchConfig
    
      @fileName ||= @@run_env[CONFIG]
      raise "No filename is set" if (@fileName ==nil)       
    
      buffer = Array.new     
      replacedomain = @domainName || Socket.gethostname()
      IO.foreach(@fileName) { |x|
        replacement =  x.gsub(/#{@TemplateName}/, replacedomain) 
        if block_given?
          yield replacement
        else
          buffer << replacement
        end
      }
      if not block_given?
        buffer
      end
    end
    
    def run
      tempfile = Tempfile::new('zimbraconf')
      fetchConfig { |line|
        tempfile.puts line
      }
      tempfile.close
      @@run_env[CONFIG] = tempfile.path 
      @@run_env['tempfile'] = tempfile #force object to stick around until program exit
      if block_given?
        yield tempfile.path
        tempfile.unlink
      else
        tempfile.path
      end
    end
    
    def to_str
      "Action: Localize zimbra configuration file"
    end
  end   
end

if $0 == __FILE__
  require 'test/unit'
  
  module Action  
    # Unit test cases for Untar
    class ZimbraTest < Test::Unit::TestCase    
        # Basic execution, the test data is testdata/cookie.tgz"     
        def testConfig()
          testObject = Action::Zimbra.new(File::join('src','ruby','action','testdata','default.conf'),nil)
          puts testObject.fetchConfig
          testObject.fetchConfig { |x|
            puts x
          }
        end
        
        def testFetchFile()
          testObject = Action::Zimbra.new(File::join('src','ruby','action','testdata','default.conf'),nil)
          fileCheck = nil
          testObject.run { |filename|
            fileCheck =  filename
            puts IO.readlines(filename)
          }
          require 'yaml'          
          puts YAML::dump(testObject)
          assert(!File.exist?(fileCheck),"Temp file deletion")
        end
    end
  end
end
