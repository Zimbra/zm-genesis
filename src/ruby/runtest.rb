#!/bin/env ruby
#
# $File: //depot/zimbra/JUDASPRIEST/ZimbraQA/src/ruby/runtest.rb $
# $DateTime: 2016/08/09 02:28:06 $
#
# $Revision: #4 $
# $Author: rvyawahare $
#
# 2006 Zimbra
#
#
getdirname = File.dirname(__FILE__)
if(Dir.pwd != getdirname)
  $:.unshift(getdirname) #append library path
end

# ensure all required gems are in place
# edit Gemfile to add new gem to requirements
# bundle_results = `bundle install` # temporary commented out to resolve integration with STAX
# puts bundle_results unless bundle_results =~ /Your bundle is complete/i

require 'log4r'
require "action"
require "model"
require "find"
require "yaml"
require 'getoptlong'
require 'timeout'

$count= 0 #serial numbering for test case execution

def time_diff(start_time, end_time)
  #calculate time elapsed
  elapsed_seconds = ((self.end_time - self.start_time)).to_i
  mins, secs = elapsed_seconds.divmod(60)
  hours, mins = mins.divmod(60)
  days, hours = hours.divmod(24)
  return days, hours, mins, secs
end

class Summary
  attr_accessor :action, :testcase, :fail_action, :fail_testcases, :known_failures
  attr_reader :start_time, :end_time
  def initialize
    @action = 0
    @testcase = 0
    @fail_action = 0
    @fail_testcases = Hash.new
    @known_failures = Hash.new
    File.foreach('/opt/qa/genesis/conf/genesis/knownfailures.txt').with_index do |line, line_num|
      known_failures[line.split("\n")[0]]=line_num
    end

    start
  end

  def start
    @start_time = Time::now
    @runHost = Socket.gethostname()
    self
  end

  def endR
    @end_time = Time::now
    self
  end

  def publishSummay
    "##{Time.now}\n" <<
    "Errors=0\n" <<
    "Failed=#{self.fail_action}\n" <<
    "Passed=#{self.action - self.fail_action}\n"
  end
  
  def updateTestRail
     if (fail_testcases.keys - known_failures.keys).count == 0 #if no new failures found
        puts "Success. No new failures found!"
        #code to update testRail, to be updated later
     else
        puts "[WARN] New failures found! Check report.txt"
     end  
  end

  def to_s
    days, hours, mins, secs = time_diff(start_time, end_time)
    pass_percent = (((self.action-self.fail_action)/(self.action.to_f))*100).round(2)
    "\n========\nSummary:\n========\n"<<
    "Start Time: #{self.start_time}\n"<<
    "Host: #{@runHost}\n"<<
    "End Time: #{self.end_time}\n" <<
    "Execution time: #{hours} hours, #{mins} mins\n"<<
    "Test Cases: #{self.testcase}\n"<<
    "Total Actions: #{self.action}\n"<<
    "Pass Percentage: #{pass_percent}%\n"<<
    "Failed Testcases: #{self.fail_testcases.keys.count}\n" <<
    "Failed Actions: #{self.fail_action}\n"<<
    "New Failed Actions: #{(fail_testcases.keys - known_failures.keys).count}\n"<<
    "\n-------------------\nNew Test Failures:\n-------------------\n"<<
    (fail_testcases.keys - known_failures.keys).sort.join("\n")<<
    #"\n-------------------\nKnown Test Failures:\n-------------------\n" <<
    #known_failures.keys.sort.join("\n")<<
    "\n-------------------\nFailed Test Cases:\n-------------------\n" <<
    fail_testcases.keys.sort.join("\n")
  end
end

class CLogger

  @@topdesc = nil
  @@toporig = nil

  attr_reader :log_path
  def initialize(topLevel)
    @topLevel = topLevel[/[\.\/]*(.*)/, 1]
    @curFileHandle = nil
    @curActionHandle = nil
    @curActionIndex = 0
    @curTestCasePath = nil
    @logger = Log4r::Logger.new 'genesislog'
    @deslogger = Log4r::Logger.new 'genesislogdesc'
    @log_path = File.join(@@topdesc, File.dirname(@topLevel), File.basename(@topLevel, '.rb'))

    MDir.rmkdir(File.join(@@topdesc, File.dirname(@topLevel)).split(File::SEPARATOR))
    f = File.open(log_path + ".txt", "a")
    p = Log4r::PatternFormatter.new(:pattern => "[%l][%d][genesis] %M")
    ps = Log4r::PatternFormatter.new(:pattern => "[%l][%d][genesis] %.80m")
    @logger.outputters = Log4r::StdoutOutputter.new 'console', :formatter => p
    @logger.add(Log4r::IOOutputter.new('console', f, {:formatter => p}))
    @deslogger.outputters = Log4r::StdoutOutputter.new 'consoledes', :formatter => ps
    @deslogger.add(Log4r::IOOutputter.new('consoledes', f, {:formatter => ps}))
  end

  def logDesc(desc)
    odesc = desc || ''
    [@deslogger].compact.each { |x|
      x.info "[##{$count}] ---> " << odesc
    }
  end

  def printMe(handle, action)
    return unless handle
    begin
      if action.pass
        handle.info action
      else
        handle.error action
      end
    rescue NoMethodError
      handle.info action
    end

  end

  def logAction(action)
    [@logger].compact.each { |x|
      printMe(x, action)
    }
  end

  def startTestCase(testcaseName)

  end

  def endTestCase

  end

  def startAction
    @curActionIndex += 1
  end

  def endAction

  end

  def CLogger.setDescPath(path)
    @@topdesc = File.expand_path(path).split(File::SEPARATOR)
    if block_given?
      yield path
    else
      path
    end
  end

  def CLogger.setOrigPath(path)
    @@toporig = File.expand_path(path).split(File::SEPARATOR)
    if block_given?
      yield path
    else
      path
    end
  end
end

require 'test/unit'

#require 'test/unit/testsuite'

class CLogger_Tests < Test::Unit::TestCase
  def setup
    CLogger.setOrigPath '/orig'
    CLogger.setDescPath '/desc'
  end

  # Test logging variable
  def test_logger
    testme = CLogger.new('/this/is/one.rb')
    assert(testme.log_path == '/desc/this/is/one')
  end

end

class TS_MyTests
  def self.suite
    suite = Test::Unit::TestSuite.new
    suite << CLogger_Tests.suite
    return suite
  end
end

def processReport(xdata, mlogger)

  begin
    mNoDump = xdata[:result].nodump
  rescue
    mNoDump = false
  end

  if(mNoDump)
    mlogger.logAction("Dump supressed")
  else
    mlogger.logAction(xdata[:result])
    xdata[:monitor].each { |mData| mlogger.logAction(mData) }
  end
end

def systemCheck
  fileCheck = ['/opt/zimbra/data/ldap/hdb/logs']
  fileCheck.map {|x| [x, File.exist?(x)] }.select {|y| y[1] == false }.map do |z|
    mTemp = Action::Command.new
    class << mTemp
      attr :check, true
      attr :pass, true
      attr :response, true
    end
    mTemp.check = true
    mTemp.pass = false
    mTemp.response = z[0] + ' missing'
    mTemp
  end
end

def has_error?(rData)
  rData.any? do |w| #report if there is any error on checking or system check failure
    begin
      w[:result].check && (!w[:result].pass)
    rescue NoMethodError
      false
    end
  end
end

#
# Run individual test cases
# Each test case has three stage, setup, action and teardown
#
def processor(testcase, report, mlogger, filter)

  $count += 1 #increment serial number
  sleep(2)
  begin
    load testcase
  rescue LoadError => e
    mlogger.startTestCase(testcase)
    mBacktrace = e.backtrace.join("\n")
    mlogger.logDesc("Load test case failure #{testcase}")
    mlogger.logDesc(e.to_s)
    mlogger.logDesc(mBacktrace)
    class << testcase
      attr :check, true
      attr :pass, true
      attr :response, true
    end
    testcase.check = true
    testcase.pass = false
    testcase.response = e.backtrace.join("\n")
    report.action += 1
    report.fail_action += 1
    report.fail_testcases[testcase] = 1
    processReport({:timeStamp => Time.now, :result => testcase, :monitor => []}, mlogger)
    mlogger.endTestCase(testcase)
    return
  rescue => e
    mlogger.startTestCase(testcase)
    mBacktrace = e.backtrace.join("\n")
    mlogger.logDesc("Load test case failure #{testcase}")
    mlogger.logDesc(e.to_s)
    mlogger.logDesc(mBacktrace)
    class << testcase
      attr :check, true
      attr :pass, true
      attr :response, true
    end
    testcase.check = true
    testcase.pass = false
    testcase.response = e.backtrace.join("\n")
    report.action += 1
    report.fail_action += 1
    report.fail_testcases[testcase] = 1
    processReport({:timeStamp => Time.now, :result => testcase, :monitor => []}, mlogger)
    mlogger.endTestCase(testcase)
    return
  end

  curTest = Model::TestCase.instance
  mlogger.startTestCase(testcase)
  mlogger.logDesc(curTest.description)
  monitors = curTest.monitor || []
  rData = []
  enviornment = {:file => mlogger.log_path}

  monitors.each do |y|
    begin
      Timeout::timeout(y.timeOut) do
        y.set(enviornment) if y.respond_to?(:set)
        y.run
      end
    rescue Timeout::Error
    end
  end # set monitor

  [curTest.setup, curTest.action, curTest.teardown].flatten.compact.each do |x|
    report.action += 1
    mlogger.startAction

    begin
      next if (filter && filter.include?(x.class))

      begin
        Timeout::timeout(x.timeOut) { x.run }
      rescue Timeout::Error
        class << x
          attr :check, true
          attr :pass, true
          attr :response, true
        end
        x.check = true
        x.pass = false
        x.response = "Step time out #{x.timeOut}"
      rescue  => detail
        class << x
          attr :check, true
          attr :pass, true
          attr :response, true
        end
        x.check = true
        x.pass = false
        x.response = detail.message + detail.backtrace.join("\n")
      ensure
        rData.push({:timeStamp => Time.now, :result => x, :monitor => []})
      end # execution

      # push system verfication
      #systemCheck.map. each do |z|
      #  rData.push({:timeStamp => Time.now, :result => z, :monitor => []})
      #end
    rescue
      puts $!
    end
  end

  need_to_dump = has_error?(rData)
  monitors.each do |y|
    begin
      y.set(:dump => true) if (need_to_dump && y.respond_to?(:set))#always report for now
      Timeout::timeout(y.timeOut) { y.fetch }
    rescue Timeout::Error
    end
  end
  if need_to_dump then
    rData.select do |mfilter|
      begin
        mfilter[:result].check && !mfilter[:result].pass
      rescue NoMethodError
        false
      end
    end.each do |z|
      report.fail_action += 1
      report.fail_testcases[testcase] = 1
      processReport(z,mlogger)
    end
  end

  mlogger.endTestCase
  report
end

#
# Travese through test case hiearchy, each test area has setup, 1 or more test cases
# and teardown
#
def run_loop(path, report, actionfilter = nil, testcasefilter = nil)

  result = begin
    mList = File.file?(path) ? path : path+'.rb'
    mList = Dir.entries(path).select do |x|
      x[0..0] != '.' && ( (x=~ /\.rb$/) || File.directory?(File.join(path,x)))
    end.map do |x|
      File.join(path,x)
    end if File.directory?(path)
    [*mList].sort! do |a, b|
      case a <=> b
      when -1,1
        case File.file?(a) && File.file?(b)
        when true
          case File.basename(a)
          when  /setup/
            -1
          when /teardown/
            1
          else
            case File.basename(b)
            when /setup/
              1
            when /teardown/
              -1
            else
              a<=>b
            end
          end
        when false
          if(File.file?(a))
            -1
          else
            1
          end
        end
      when 0
        0
      end
    end
  rescue
    result = [path]
  end

  #llogger = CLogger.new(path)
  result.each do |x|
    begin
      if(File.directory?(x))
        report = run_loop(x, report, actionfilter, testcasefilter)
      else
        next if  (not File.exist?(x))
        next if (testcasefilter && (not testcasefilter.include?(x)))
        report.testcase += 1
        llogger = CLogger.new(x)
        puts "Executing testcase #{x}"
        report = processor(x, report, llogger, actionfilter)
      end
   
    rescue
      puts $!
    end
  end

  if block_given?
    yield report
  else
    report
  end
end

class ActionFilter

  attr_writer :active, :filters
  def initialize(value = nil, active = false)
    @active = active
    @filters = value
  end

  def include?(value)
    return false if not @active
    @filters.include?(value)
  end

end

class TestFilter < ActionFilter
  def include?(value) #this is negative filter if there is no filter everything is in
    return true if not @active
    super(File.basename(value, ".rb"))
  end
end

class MDir < Dir
  def MDir.rmkdir(dataarray = [])
    carry = nil
    MDir.cleanupPath(dataarray) do |y|
      y.flatten.each do |x|
        carry = File.join([carry, x].compact)
        if(not File.exist?(carry))
          mkdir(carry)
          File.chmod(0777, carry) #change from root to zimbra, have to relax permission
        end
      end
    end

    if block_given?
      yield carry
    else
      carry
    end
  end

  def MDir.cleanupPath(pathArray)
    #take care of platform issue
    return pathArray unless (pathArray.length > 1)

    result = if(pathArray[0]== '')
      if(pathArray.length == 2)
        [File.join(pathArray[0..1])]
      else
        [File.join(pathArray[0..1])] + pathArray[2..-1]
      end
    else
      pathArray
    end

    if block_given?
      yield result
    else
      result
    end
  end
end

def getOptions
  [
    ['-h', GetoptLong::NO_ARGUMENT],
    ['--noinstall', GetoptLong::NO_ARGUMENT],
    ['--plan',GetoptLong::REQUIRED_ARGUMENT],
    ['--log',GetoptLong::REQUIRED_ARGUMENT],
    ['--testcase',GetoptLong::REQUIRED_ARGUMENT],
    ['--test', GetoptLong::NO_ARGUMENT]
  ]
end

filter = TestFilter.new
install = ActionFilter.new

def selftest
  require 'test/unit/ui/console/testrunner'
  Test::Unit::UI::Console::TestRunner.run(TS_MyTests)
end

#ARGV << "-h" if (ARGV.length == 0)
@logdest = File.dirname(__FILE__)
GetoptLong.new(*getOptions).each do | opt, arg|
  case opt
  when '-h' then
    puts "-h this message"
    puts "--noinstall do not perform install operation"
    puts "--plan test plan file"
    puts "--log log location"
    puts "--testcase run the test"
    exit
  when '--noinstall' then
    install.active = true
    install.filters = [Action::GetBuild, Action::Untar, Action::Install]
  when '--plan' then
    @testList = open(arg) do |io|
      io.readlines.select {|x| !x.nil? && x =~ /\S+/ && x[0..0] != '#' }.map do |x|
        File.join(File.dirname(__FILE__), x.strip)
      end
    end
  when '--testcase' then
    @testList = [arg]
  when '--log' then
    @logdest = arg
  when '--test' then
    selftest
    exit
  end
end

if(@logdest)
  CLogger.setDescPath(MDir.rmkdir([@logdest, 'log']))
else
  CLogger.setDescPath(MDir.rmkdir([Dir.pwd, 'log', Socket.gethostname, Time.now.to_i.to_s]))
end

report = Summary.new
if(@testList)
  i = 0 
  @testList.each do |x|
    begin #ignore all errors
      report = run_loop(CLogger.setOrigPath(x), report, install, filter)
    rescue
      puts $!
    end
    
  end   
  
  open(File.join(@logdest,"report.txt"),"a") do |mfile|
    mfile.puts report.endR.to_s
  end

  open(File.join(@logdest,"testsummary.txt"),"a") do |mfile|
    mfile.puts report.publishSummay
  end
  #update testRail
  report.updateTestRail
end
exit #required or Test::Unit will run, lame

