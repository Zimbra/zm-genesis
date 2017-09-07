#!/bin/ruby
#
# $File$ 
# $DateTime$
#
# 
# Generate jscoverage report
#
require 'getoptlong'
require 'log4r'
require 'yaml'
require 'net/http'
require 'rexml/document'



include Log4r

module Jscov
  
  #Logger setup
  Logger = Logger.new 'reportlog'
  Logger.outputters = StdoutOutputter.new 'console',
  :formatter => PatternFormatter.new(:pattern => "[%l][%d][jscov-report] %M")
  Logger.level = INFO
  Logger.level = DEBUG if $DEBUG
  
  
  #list of directory to scan for jaf files
  list = %w(/opt/zimbra/jetty/webapps/service/WEB-INF)
  list = list + %w(/opt/zimbra/jetty/webapps/zimbra/WEB-INF/lib /opt/zimbra/jetty/common/lib)
  @ptms = ENV['tms'] || 'zqa-tms.eng.vmware.com'
  
  def Jscov.getOptions
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
  @suite = 'Jscov'

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

  def Jscov.get_summary(filename)
    return [] unless File.exist?(filename)
    fh = File.open(filename, 'r')
    xml_data = fh.readline(nil)
    fh.close
    result_data = xml_data.slice(xml_data.index('<?xml version'),
                                 xml_data.index('</all')) +
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
  
  
  def Jscov.report_result(host_url, report_directory, build_id, suite = 'ZCS')
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
  

  if(!@unit_test)  
    
    Logger.info("Generating report ")
    if @norun
      Logger.debug("Report is not run since no run switch is set")
    else
      #Report result if there is a coverage report
      if(File.exist?(File.join(@destination, 'coverage','index.html')))
        report_result('http://%s'%@ptms, @destination, @build_id, @suite) 
      end
    end
    
    exit
  end

  puts "Start Unit Testing"
  require 'test/unit'

  class TestCaseTest < Test::Unit::TestCase
    def test_get_summar
      result = Jscov.get_summary('/opt/qa/testlogs/UBUNTU10_64/main/20110610050101_FOSS/SelNG-projects-ajax-tests/130771352265581/zqa-429.eng.vmware.com/coverage.xml')
      puts YAML.dump(result)
    end
  end

end
