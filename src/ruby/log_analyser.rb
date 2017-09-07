#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$

# log_analyser is designed to parse summary.txt log of genesis framework
# to gather some information on how long it takes to run this or that
# test suite.
#
# running this script results in sorted list of test cases and a histogram
# of test destibution per time, where "zero" bucket is for tests that ran 0 seconds
# and 0:01 shows all tests that ran for 0:01 to 0:30 seconds

require 'time'
require 'open-uri'


class LogAnalyser
  
  def initialize(log)
    # config vars
    @bucket_step = 30 # step through 30 seconds for each bucket
    @histo_size = 50  # width of the histogram
    
    # service vars
    @total_time = 0
    @total_tests = 0
    @tests = []
    @longest = 0
    @buckets = {}
    
    read_log(log)
  end
  
  def to_s
    str = ''
    @tests.each do |test|
      str << "- - Name:     #{test[0]}\n"
      str << "  - Duration: #{to_time(test[2])}\n"
    end

    return str
  end
  
  def total_to_s
    mm, ss = @total_time.divmod(60)
    hh, mm = mm.divmod(60)
    str = "\nTotal duration: " + hh.to_s + ':' + mm.to_s + ':' + ss.to_s
    str << "\nTotal tests: " + @total_tests.to_s

    return str
  end
  
  def print_all_tests
    str = "\n"
    @tests.sort { |a, b| a[2] <=> b[2] }.each do |test|
      str << "- - Name:     #{test[0]}\n"
      str << "  - Duration: #{to_time(test[2])}\n"
    end
    str << total_to_s
    
    return str
  end
  
  def print_histogram
    str = "\n"
    to_buckets
    
    normalize.each do |v|
      str << "# #{to_time(v[0].to_i * @bucket_step + 1)} |"
      str << "#{('#' * v[2]).ljust(@histo_size)} | #{v[1].to_s.ljust(5)} | "
      str << "#{v[3].to_s.ljust(3)}%\n"
    end
    
    return str
  end
  
  private

  def read_log(log)
    open(log).each do |line|
      if line.include?('[INFO]')
        test_name = line.match(/--->(.*)$/)[1]
        test_start = Time.parse(line.match(/\]\[(.*)\]\[/)[1])
        unless @tests.empty?
          @tests.last[2] = test_start.to_i - @tests.last[1].to_i
          @total_time += @tests.last[2]
          @longest = @tests.last[2] if @tests.last[2].to_i > @longest
        end
        @tests.push([test_name, test_start, 0])
        @total_tests += 1
      end
    end
  end
  
  def to_buckets
    #def calculate number of bucketes
    bucket_number = @longest / @bucket_step
    # step through each bucket
    # start with -1 to put all tests with legth = 0 into separate bin
    -1.step(bucket_number) do |b|
      #select all tests with time >= bucket_num * @bucket_step
      @buckets[b] = @tests.select do |test|
        (test[2] > b * @bucket_step) && (test[2] <= (b + 1) * @bucket_step)
      end
    end
  end
  
  def normalize
    buck = []
    largest_bin = 0
    @buckets.each do |k, v|
      buck[k+1] = [k.to_s, v.size]
      largest_bin = v.size if v.size > largest_bin
    end
    
    buck.map do |b|
      if b[1] > 0
        b[2], b[3] = @histo_size / (largest_bin / b[1]), (b[1] * 100) / @total_tests
      else
        b[2], b[3] = 0, 0
      end
    end
    
    return buck
  end
  
  def to_time(seconds)
    if seconds.to_i < 0
      return "zero".ljust(5)
    else
      return "#{seconds.to_i.divmod(60)[0]}:#{seconds.to_i.divmod(60)[1].to_s.rjust(2, '0')}".ljust(5)
    end
  end
end


if ARGV[0].nil? or ARGV[0].match(/^-/)
  puts "Usage: #{__FILE__} <path or link to summary.txt>"
  exit
end

log = LogAnalyser.new(ARGV[0])
puts log.print_all_tests
puts log.print_histogram
