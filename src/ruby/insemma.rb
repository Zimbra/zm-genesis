#!/bin/ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
#
# Setup system for emma

require 'getoptlong'
require 'log4r'
require 'yaml'

include Log4r

module Emma
  
  #Logger setup
  Logger = Logger.new 'reportlog'
  Logger.outputters = StdoutOutputter.new 'console',
  :formatter => PatternFormatter.new(:pattern => "[%l][%d][emma-report] %M")
  Logger.level = INFO
  Logger.level = DEBUG if $DEBUG
  
  EMMADIR = '/var/tmp' #directory where emma.jar sits
  ZIMBRASRC = '/var/tmp/zcs-src' #directory where zimbra sourcefile sits
  JAVAOPTIONS = '-Xms1g -Xmx2g' #run with 1g heap at start 2g max
  FILTERS = ['-org.*',
             '-com.zimbra.cs.license.*',
             '-com.zimbra.qa.*',
             '-com.zimbra.*Test*',
             '-com.zimbra.cs.service.NetworkDocument',
             '-com.zimbra.kabuki.*',            
             '-com.zimbra.cs.account.AttributeManagerUtil*',
             '-com.zimbra.cs.account.FileGenUtil*',
             '-com.zimbra.cs.account.ProvUtil*',             
             '-com.zimbra.cs.account.ZAttrAccount*',
             '-com.zimbra.cs.account.ZAttrCos*',
             '-com.zimbra.cs.account.ZAttrConfig*',
             '-com.zimbra.cs.account.ZAttrCalendarResource*', 
             '-com.zimbra.cs.account.ZAttrServer*',
             '-com.zimbra.cs.account.ZAttrDomain*',
             '-com.zimbra.cs.account.ZAttrDistributionList*',
             '-com.zimbra.cs.account.ZAttrProvisioning*',
             'com.zimbra.*']
  
  #list of directory to scan for jaf files
  list = %w(/opt/zimbra/jetty/webapps/service/WEB-INF)
  list = list + %w(/opt/zimbra/jetty/webapps/zimbra/WEB-INF/lib /opt/zimbra/jetty/common/lib)
  
  def Emma.getOptions
    [
     ['-h', GetoptLong::NO_ARGUMENT],
     ['--norun',  GetoptLong::NO_ARGUMENT],
     ['--verbose', GetoptLong::NO_ARGUMENT],
     ['--test', GetoptLong::NO_ARGUMENT]
    ]
  end

  ::GetoptLong.new(*getOptions).each do | opt, arg|
    case opt
    when '-h' then 
      puts "-h this message" 
      puts "--log test log directory"
      puts "--run run the test"
      exit
    when '--norun' then
      @norun = true
    when '--verbose' then
      Logger.level = DEBUG
    when '--test' then
      @unit_test = true
    end  
  end
  
  def Emma.get_zimbra_jars(directory)
    Logger.debug("Enter get zimbra jars")
    Logger.debug(directory)
    `find #{directory} -follow -name 'zim*.jar' 2>/dev/null`.split.map { |y| y.chomp }.sort { |a, b| File.stat(b) <=> File.stat(a)}
  end
  
  def Emma.has_debug_files(list)
    Logger.debug("Enter has debug file")
    Logger.debug("List #{YAML.dump(list)}")
    Logger.debug(" /var/tmp/zcs-src.tgz is missing") unless File.exist?('var/tmp/zcs-src.tgz')
    File.exist?('/var/tmp/zcs-src.tgz') && list.any? do |x|
      result = get_zimbra_jars(x)
      if(result.size > 0)
        Logger.debug("Scanning #{result.first}")
        cresult =  `zipgrep -i LineNumberTable #{result.first} 2>/dev/null`
        Logger.debug(cresult)
        cresult.size > 0
      else
        false
      end
    end
  end
  
  def Emma.get_inst_commands(list)
    
    Logger.debug("Enter get_inst_commands")
    Logger.debug("Scan directories : #{YAML.dump(list)}")
    list.map do |x|
      result = get_zimbra_jars(x)
      if(result.size > 0)
        result = ' -ip ' + result.join(' -ip ')
      else
        result = ''
      end
      ['cp '+File.join(EMMADIR, 'emma.jar')+ " #{x}",
       "cd #{x};/opt/zimbra/bin/zmjava -cp ./emma.jar emma instr #{result} -out data.em" +
       " -merge y -m overwrite -ix #{FILTERS.join(',')}"
      ]
    end.flatten
  end
  
  # Change permission on directories
  def Emma.add_instructions(list)
    ['sudo -u zimbra /opt/zimbra/bin/zmcontrol stop 2>/dev/null'] + 
      list + 
      ['/opt/zimbra/libexec/zmfixperms 2>/dev/null'] +
      ['sudo -u zimbra /opt/zimbra/bin/zmlocalconfig -e mailboxd_java_options="`/opt/zimbra/bin/zmlocalconfig -m nokey mailboxd_java_options` -noverify"'] +
      ['sudo -u zimbra /opt/zimbra/bin/zmcontrol start 2>/dev/null']
  end

  if(!@unit_test)  
    # Check to see if the jars has debug symbol
    if(has_debug_files(list))
      clist = add_instructions(get_inst_commands(list))  
      Logger.debug("Command #{YAML.dump(clist)}")
      Logger.info("Generating report....")
      if @norun
        Logger.info("Report is not run since no run switch is set")
      else
        clist.each { |x| 
          Logger.info "Running #{x}"
          Logger.info `#{x}`
        }
      end
    else
      Logger.info("Can not find any jar file with debug symbol, no instrumentation")
    end
    exit
  end

  puts "Start Unit Testing"
  require 'test/unit'

  class TestCaseTest < Test::Unit::TestCase
    def test_logger
      Emma::Logger.debug("logger test")
    end
    
    def test_findem
      list = %w(./tmp)
      Emma::Logger.debug((Emma.get_inst_commands(list)))
      assert(Emma.get_inst_commands(list).size%2 == 0) #two instructions are generated
    end
    
    def test_fixperms
      puts YAML.dump(Emma.add_instructions(%w(hi)))
    end
    
    def test_has_debug_files
      assert(!Emma.has_debug_files(%w(./tmp)))
    end
  end

end

