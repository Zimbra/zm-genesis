#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
#
#
require 'getoptlong'
require 'yaml'




class TestCaseList < Array
end

class Util
  def Util.parse_bugzilla_file(file_name, &block)
    result_hash = Hash.new
    File.open(file_name).each_line do |line|
      processed = yield line.split
      if(processed)
        (processed = result_hash[processed.to_s] + processed) if result_hash.has_key?(processed.to_s)
        result_hash[processed.to_s] = processed
      end
    end
    result_hash
  end
end

class TestCase < String
  attr_accessor :bug_ids, :bug_list
  
  def initialize(*env)
    super(*env)
    self.bug_list = { }
    self.bug_ids = []
  end
  
  def find_bug(this_bug)
    raise "Dont have bug #{bug_ids}" unless bug_ids.include?(this_bug)
    bug_list[this_bug]
  end
  
  def active?
    #A test case is active if there is a bug that is active
    bug_list.any? { |k, v| v.active?}
  end

  def populate_bug_list(bug_id_list)
    bug_ids.each do |this_bug|
      if(bug_id_list.has_key?(this_bug))
        self.bug_list[this_bug] = bug_id_list[this_bug]
      end
    end
    self
  end
  
  def +(val)
    add_test_case = TestCase.new(self.to_s)
    add_test_case.bug_ids = self.bug_ids + val.bug_ids
    add_test_case
  end
  
  def TestCase.parse_report_file(file_name)
    list = File.open(file_name).select do |line|
      line.include?('data')
    end.map do |x| 
      TestCase.new(x.chomp.sub(/.*?data/,'/data').downcase) 
    end
    TestCaseList.new(list.uniq)
  end
  
  def TestCase.sanitized_name(test_name)
    
    test_name = test_name.gsub(/\\/,'/') #slash translation
    test_name = test_name.sub(/^.*genesis\//,'').downcase #genesis header removal and downcase
    test_name = test_name.sub(/^.*data\//,'') #strip data as well
    test_name = '/data/' + test_name #data header append
    
  end
  
  def TestCase.get_bug_list(file_name)
    Util.parse_bugzilla_file(file_name) do |data|
      if not data.first.include?('.rb')
        nil
      else
        #santizied_name = TestCase.santizied_name(data.first)
        
        new_test_case = TestCase.new(TestCase.sanitized_name(data.first))
        new_test_case.bug_ids = data[1..-1]
        new_test_case
      end
    end
  end
end

class Bug < String
  attr :state, true
  attr :contacts, true
  
  def initialize(*env)
    super
    self.contacts = []
  end
  
  def active?
    (state == :NEW) || (state == :ASSIGNED) || (state == :REOPENED)
  end
  
  def +(val)
    #ignore the additional entry
    self
  end
  
  def populate_contact_from_list(contacts_list)
    if(contacts_list.has_key?(self.to_s))
      self.contacts = contacts + contacts_list[self.to_s].name
    end
  end
  
  def Bug.get_bug_list(file_name)
    Util.parse_bugzilla_file(file_name) do |data|
      new_bug = Bug.new(data.first)
      new_bug.state = data[1].to_sym
      new_bug
    end
  end
  
end

class Contact < String
  attr :name, true
  
  def +(val)
    self.name = name + val.name
  end
  
  def Contact.get_contact_list(file_name)
    Util.parse_bugzilla_file(file_name) do |data|
      new_contact = Contact.new(data.first)
      new_contact.name = data[1..-1]
      new_contact
    end
  end
end

def getOptions
  [
   ['-h', GetoptLong::NO_ARGUMENT],
   ['--database', GetoptLong::REQUIRED_ARGUMENT],
   ['--log',GetoptLong::REQUIRED_ARGUMENT],
   ['--verbose', GetoptLong::NO_ARGUMENT],
   ['--test', GetoptLong::NO_ARGUMENT]
  ]
end

GetoptLong.new(*getOptions).each do | opt, arg|
  case opt
  when '-h' then 
    puts "-h this message" 
    puts "--database directory where bugzilla database sits"
    puts "--log test log directory"
    puts "--run run the test"
    exit
  when '--database' then
    @database_root = arg
  when '--log' then
    @log_root = arg
  when '--verbose' then
    @verbose = true
  when '--test' then
    @test = true
  end  
end


def generate_report(failed, bug_data)
  regressed = []
  new_bugs = []
  failed.each do |failed_case|
    # if it isn't reported new bug
    failed_string = failed_case.to_s
    if(bug_data.has_key?(failed_string))
      current_case = bug_data[failed_string]
      unless(current_case.active?)
        current_case.bug_ids.each do |x|    
          current_bug = current_case.find_bug(x)
          bug_state = ''
          contacts_output = 'NONE'
          if(current_bug)
            bug_state = current_bug.state
            if(current_bug.contacts.size > 0)
              contacts_output = current_bug.contacts.sort.join(', ')              
            end
          end
          regressed.push "#{failed_string}, #{contacts_output}" + 
             ", #{bug_state}, http://bugzilla.zimbra.com/show_bug.cgi?id=#{x} "
        end
      end
    else
      new_bugs.push "#{failed_string} -- http://bugzilla.zimbra.com/enter_bug.cgi"
    end
  end
  [regressed.sort, new_bugs.sort]
end

def print_header(output_string)
  "\n#{output_string}\n" + '='*78
end

def write_report(regressed, new_bugs)
  if(@verbose)
    puts print_header('NEW')
    puts new_bugs.join("\n")
    puts print_header('REGRESSED')
    puts regressed.join("\n")  
  end
  File.open(@bug_report_file, 'w') do |outputter|
    outputter.puts  print_header('NEW')
    outputter.puts new_bugs.join("\n")
    outputter.puts print_header('REGRESSED')
    outputter.puts regressed.join("\n") 
  end
end

if(!@test)
  @database_root = @database_root || File.join(File.dirname(__FILE__), '..', '..', 'test', 'bugcheck')
  @log_root = @log_root || @database_root 
  bug_status_db = File.join(@database_root, 'bugStatus.txt')
  test_case_db = File.join(@database_root, 'bugTestcase.txt')
  report_file = File.join(@log_root,'report.txt')
  contact_file = File.join(@database_root, 'bugQaContact.txt')
  @bug_report_file = File.join(@log_root,'BugReport.txt')
  
  # Get contact list
  contact_list = Contact.get_contact_list(contact_file)
  puts YAML.dump(contact_list) if @verbose
 
  # Get a list of bugs from bugzilla database dump
  bug_list = Bug.get_bug_list(bug_status_db)
  bug_list.each do |key, val|
    val.populate_contact_from_list(contact_list)
  end
  puts YAML.dump(bug_list) if @verbose
  
 # Get a list of test cases from bugzilla database dump and merge it with the bug list
  test_cases = TestCase.get_bug_list(test_case_db).each do |key, val|
    val.populate_bug_list(bug_list)
  end

  # Get a list of failure from the genesis report
  fail_test_cases = TestCase.parse_report_file(report_file)
  puts YAML.dump(fail_test_cases) if @verbose

  # Write out the report
  write_report(*generate_report(fail_test_cases, test_cases))
  exit
end

puts "Start Unit Testing"
require 'test/unit'

module ShareData
  
  attr_accessor :database_root, :log_root, :bug_status_db, :test_case_db, :report_file, :contact_file
  
  def setup
    @database_root = File.join(File.dirname(__FILE__), '..', '..', 'test', 'bugcheck')
    @log_root = @database_root
    @bug_status_db = File.join(@database_root, 'bugStatus.txt')
    @test_case_db = File.join(@database_root, 'bugTestcase.txt')
    @report_file = File.join(@log_root,'report.txt')
    @contact_file = File.join(@database_root, 'bugQaContact.txt')
  end
  
end

class TestCaseTest < Test::Unit::TestCase
  
  include ShareData
  
  def test_new
    test = TestCase.new('hi')
    assert(TestCase === test)
  end
  
  def test_parse_report
    fail_test_cases = TestCase.parse_report_file(report_file)
    assert(fail_test_cases.first == '/data/backuprestore/abort/abortbasic.rb')
    #puts YAML.dump(fail_test_cases)
  end
  
end

class BugTest < Test::Unit::TestCase
  
  include ShareData
  
  def test_new
    assert(Bug === Bug.new('234'))
  end
  
  def test_get_bug_list
    bug_list = Bug.get_bug_list(bug_status_db)
    assert(bug_list.first.first == "5862")
    assert(bug_list.first[1].state == :VERIFIED)
    puts YAML.dump(bug_list) if @verbose
  end
end

class ContactTest < Test::Unit::TestCase
  include ShareData
  
  def test_get_contact_list
    contact_list = Contact.get_contact_list(contact_file)
    assert(contact_list.include?('35166') == true)
    #puts YAML.dump(contact_list)
  end
end
