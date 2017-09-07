#!/bin/ruby
#
# $File$ 
# $DateTime$
#
# 
# Generate emma report
#
#require 'rubygems' #only for development purpose as gem is not installed in most testbed
require 'getoptlong'
require 'log4r'
require 'yaml'
require 'net/http'
require 'rexml/document'

include Log4r

module Emma
  
  #Logger setup
  Logger = Logger.new 'reportlog'
  Logger.outputters = StdoutOutputter.new 'console',
  :formatter => PatternFormatter.new(:pattern => "[%l][%d][emma-report] %M")
  Logger.level = INFO
  Logger.level = DEBUG if $DEBUG
  
  EMMADIR = '/var/tmp' #directory where emma.jar sits
  ZIMBRASRC = '/var/tmp/zcs-src/src' #directory where zimbra sourcefile sits
  JAVAOPTIONS = '-Xms1g -Xmx2g' #run with 1g heap at start 2g max
  
  #list of directory to scan for jaf files
  list = %w(/opt/zimbra/jetty/webapps/service/WEB-INF)
  list = list + %w(/opt/zimbra/jetty/webapps/zimbra/WEB-INF/lib /opt/zimbra/jetty/common/lib)
  @ptms = ENV['tms'] || 'zqa-tms.eng.vmware.com'
  
  def Emma.getOptions
    [
     ['-h', GetoptLong::NO_ARGUMENT],
     ['--build_id', GetoptLong::OPTIONAL_ARGUMENT],
     ['--log',GetoptLong::OPTIONAL_ARGUMENT],
     ['--norun',  GetoptLong::NO_ARGUMENT],
     ['--verbose', GetoptLong::NO_ARGUMENT],
     ['--test', GetoptLong::NO_ARGUMENT],
     ['--suite',  GetoptLong::OPTIONAL_ARGUMENT],
     ['--tms', GetoptLong::OPTIONAL_ARGUMENT],
    ]
  end
  
  @destination = ''
  @build_id = 0

  ::GetoptLong.new(*getOptions).each do | opt, arg|
    case opt
    when '-h' then 
      puts "-h this message" 
      puts "--log test log directory"
      puts "--run run the test"
      exit
    when '--build_id' then
      @build_id = arg
    when '--database' then
      @database_root = arg
    when '--log' then
      @destination = arg
    when '--norun' then
      @norun = true
    when '--verbose' then
      Logger.level = DEBUG
    when '--test' then
      @unit_test = true
    when '--suite' then
      @suite = arg
    when '--tms' then
      @ptms = arg  
    end  
  end
  
  def Emma.findEMFiles(list)
    
    Logger.debug("Enter findEMFiles")
    Logger.debug("Scan directories : #{YAML.dump(list)}")
    list.map do |x|
      result = `find #{x} -follow -name '*.em' 2>/dev/null`
      if (result =~ /em/)
        result.split.map {|y| y.chomp}.join(' -in ')
      else
        nil
      end
    end.compact.join(' -in ')
  end
  
  def Emma.add_untar_commands
    ['/bin/rm -r -f /var/tmp/zcs-src', 
     'mkdir -p /var/tmp/zcs-src', 
     'tar -C /var/tmp/zcs-src -xzf zcs-src.tgz',
    'mv /var/tmp/zcs-src/* /var/tmp/zcs-src/src']
  end
  
  # Change permission on directories
  def Emma.add_instructions(list)
    ['sudo -u zimbra /opt/zimbra/bin/zmcontrol stop 2>/dev/null'] + 
      add_untar_commands +
      [*list] + 
      ['sudo -u zimbra /opt/zimbra/bin/zmcontrol start 2>/dev/null']
  end
  
  def Emma.is_instrumented(list)
    Logger.debug("Enter is instrumented")
    Logger.debug("List #{YAML.dump(list)}")
    list.any? do |x|
      `find #{x} -follow -name '*.em' 2>/dev/null` =~ /em/
    end
  end
  
  def Emma.getSrcDirectory
    [%w(ZimbraServer src java), %w(ZimbraCommon src java), %w(ZimbraTagLib src java)].map do |x|
      File.join(ZIMBRASRC, x)
    end
  end
  
  def Emma.generate_report_commands(list, destination)
    clist = findEMFiles(list)
    clist = " -in /opt/zimbra/log/coverage.ec -in #{clist}" if clist.size > 0
    srcList = getSrcDirectory.join(' -sp ')
    srcList = "-sp #{srcList}" if srcList.size > 0
    destinationES = File.join(destination, 'coverage.es')
    
    if(File.exist?(destinationES))
      mlist = "-in %s %s"%[destinationES, clist]
    else
      mlist = clist
    end
    
    commands = ["merge #{mlist} -out #{destinationES}", 
             "report -r html,xml -in #{destinationES} #{srcList}"]
    commands = commands.map do |command|
      "cd #{destination};/opt/zimbra/bin/zmjava #{JAVAOPTIONS} -cp #{File.join(EMMADIR,'emma.jar')} emma #{command}"
    end
    [
     "/bin/rm -r -f #{File.join(destination,'coverage')}",  #Erase previous result
     "mkdir -p #{destination}",
     commands,
    ].flatten
  end
  
  def Emma.report_result(host_url, report_directory, build_id, suite = 'ZCS')
    url = URI.parse(host_url)
    true_directory = File.join(report_directory, 'coverage')
    res = Net::HTTP.start(url.host, url.port) do |http|
      request = "/coverage/add_coverage?build_id=#{URI.escape(build_id.to_s)}&log_directory=#{URI.escape(true_directory)}&suite=#{URI.escape(suite)}"
      extras = get_summary(File.join(report_directory, 'coverage.xml'))
      if(extras.size > 0) #we have rollup data
        request = request + '&%s'%extras.map {|x| x.join('=')}.join('&')
      end
      Logger.info("Sending #{request} to #{host_url}")
      http.get(request)
    end
    Logger.debug(res.body)
  end


# data format
# <report>
#   <stats>
#     <packages value="158"/>
#     <classes value="4740"/>
#     <methods value="38102"/>
#     <srcfiles value="3104"/>
#     <srclines value="202617"/>
#   </stats>
#   <data>
#     <all name="all classes">
#       <coverage type="class, %" value="56%  (2642/4740)"/>
#       <coverage type="method, %" value="43%  (16433/38102)"/>
#       <coverage type="block, %" value="43%  (425121/979752)"/>
#       <coverage type="line, %" value="44%  (89560/202617)"/>
  def Emma.get_summary(filename)
    return [] unless File.exist?(filename)
    fh = File.open(filename, 'r')
    xml_data = fh.readline(nil)
    fh.close
    result_data = xml_data.slice(xml_data.index('<?xml version'),
                                 xml_data.index('<package ')) +
      '</all></data></report>'
    doc = REXML::Document.new(result_data)
    result = []
    doc.get_elements('//coverage').each do |x|
      #puts x.methods.sort
      key = x.attributes['type'].split(/,/).first rescue nil
      values = (x.attributes['value'].split(/\s+/).last[1..-2].split(/\//)) rescue nil
      unless(key.nil?)
        keys = ['cc','c'].map {|x| key+x }
        result = result + keys.zip(values)
      end
    end
    Logger.debug("extra string %s"%YAML.dump(result.map {|x| x.join('=')}.join('&')))
    #puts result_data
    result
  end
  

  if(!@unit_test)  
    
    unless(is_instrumented(list))
      Logger.info("No instrumented data found exiting..")
      exit
    end
    
    @destination ||= '.'
    clist = generate_report_commands(list, @destination)
    clist = add_instructions(clist)
    if(@suite)
      clist = clist + add_instructions(generate_report_commands(list, File.join(@destination, @suite)))
    end

    Logger.debug("Command #{YAML.dump(clist)}")
    Logger.info("Generating report ")
    if @norun
      Logger.debug("Report is not run since no run switch is set")
    else
      clist.each do |x|
        Logger.info "Running #{x}"
        Logger.info `#{x}`
      end  
      #Report result if there is a coverage report
      if(File.exist?(File.join(@destination, 'coverage')))
        report_result('http://%s'%@ptms, @destination, @build_id) 
      end
      if(@suite && File.exist?(File.join(@destination, @suite, 'coverage')))
              report_result('http://%s'%@ptms, File.join(@destination, @suite), @build_id, 'ZCS.%s'%@suite.downcase)
      end
    end
    
    exit
  end

  puts "Start Unit Testing"
  require 'test/unit'

  class TestCaseTest < Test::Unit::TestCase
    def test_get_summar
      Emma.get_summary('/opt/qa/testlogs/CodeCoverage/ZCS/emma/main/20110525050101_FOSS/Smoke/coverage.xml')
    end
    def test_logger
      Emma::Logger.debug("logger test")
      puts @ptms
    end
    
    def test_findem
      list = %w(/tmp)
      assert(Emma.findEMFiles(list).size == 0)
    end
    
    def test_getSrcDirectory
      puts YAML.dump(Emma.getSrcDirectory)
    end
    
    def test_is_insturmented
      puts Emma.is_instrumented(%w(/opt/zimbra/jetty))
    end
    
    def test_resport_result
      puts Emma.report_result("http://localhost:3000", '/opt/qa/testlogs/CodeCoverage/ZCS/emma/main/foo', 17476)
    end
  end

end
