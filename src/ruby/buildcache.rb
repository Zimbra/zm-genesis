#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2012 VMWARE
#
# Fetching ZCA builds from the buildweb
#
require 'json'
require 'net/http'
require 'time'
require 'uri'
require 'yaml'

TOPDEST = '/opt/qa/zqa3/builds'

def extract_builds(data)
  data['_list'].collect do |row|
    #puts YAML.dump(element)
    branch = row['_branch_url']
    branch = branch.chop.split(/\//).last
    {:id => row['id'], :product => row['product'], :deliverable_url => row['_deliverables_url'], :branch => branch,
      :endtime => Time.parse(row['endtime'])}
  end
end

def extract_downloads(data)
  data['_list'].collect do |row|
    { :path => row['path'], :download_url => row['_download_url'], :exit_status => 0 }
  end
end

def filter_by(data, filter = ['ova'])
  data.find_all do |row|
    filter.any? do |test|
      row[:path].include?(test)
    end
  end
end

def build_label(my_time)
  my_time.strftime('%Y%m%d%H%M%S_ZCA')
end

def construct_dest_path(data, topdest, build)
  data.each do |row|
    row[:dest_path] = File.join(topdest, build[:product], build[:branch], build[:id].to_s, build_label(build[:endtime]))
  end
  data
end

def get_deliverables(uri, data)
  res = Net::HTTP.start(uri.host, uri.port) do |http|
    data.map do |row|
    request_uri =  "%s&_format=json&path__contains=ova"%row[:deliverable_url]
      request = Net::HTTP::Get.new request_uri
      response = http.request request 
      result = JSON.parse(response.body)
      row[:deliverables] = construct_dest_path(filter_by(extract_downloads(result)), TOPDEST, row)     
    end
  end 
  data
end

def make_directories(data)
  data.each do |rows|
    rows[:deliverables].each do |row|
      directory = row[:dest_path]
      unless Dir.exist?(directory)
        exit_string = `mkdir -p #{directory} 2>&1` #no assumption is make if path is the same for data in rows
        row[:exit_status] = $?.exitstatus
        row[:exit_string] = "%s %s"%[exit_string, directory]
      end
    end
  end
  data
end

def do_addbuilds(data)
  data.each do |rows|
    my_build_label = build_label(rows[:endtime])
    rows[:deliverables].each do |row|
      if(row[:exit_status] == 0)
        destination_url = 'http://zqa-362.eng.vmware.com/%s/'%row[:dest_path].split('/')[4..-1].join('/')
        notify_url = 'http://zqa-tms.eng.vmware.com/builds/addBuild?arch=STUDIO26&branch=%s&name=%s&url=%s'%[rows[:branch], my_build_label, URI.escape(destination_url)]
        my_uri = URI.parse(notify_url)
        res = Net::HTTP.start(my_uri.host, my_uri.port) do |http|   
          http.read_timeout = 60000
          request = Net::HTTP::Get.new my_uri.request_uri
          response = http.request request 
          puts response
        end
      end
    end
  end
  data
end

def do_wgets(data)

   data.each do |rows|
    rows[:deliverables].each do |row| 
      # dont bother with wget if file already exist
      file_name = File.join(row[:dest_path], 'zca.ova')
      if(File.exist?(file_name))
        row[:exit_status] = 1
        row[:exit_string] = 'no wget file exist'
      end
      
      if(row[:exit_status] == 0)
        command = "wget -nv --no-proxy -O %s %s"%[file_name, row[:download_url]]
        puts 'Running: %s'%command
        exit_string = `#{command} 2>&1`
        row[:exit_status] = $?.exitstatus
        row[:exit_string] = exit_string
      end

    end
  end

  data
end

uri = URI.parse('http://buildapi.eng.vmware.com/ob/build/?_limit=10000&_order_by=-id&product=zca&buildstate=succeeded&ondisk=True&&_format=json')
begin
  res = Net::HTTP.start(uri.host, uri.port) do |http|   
    http.read_timeout = 60000
    request = Net::HTTP::Get.new uri.request_uri
    response = http.request request 
  end
  build_set = JSON.parse(res.body)
  result =  extract_builds(build_set)
  data_set = do_addbuilds(do_wgets(make_directories(get_deliverables(uri, result))))
  
  puts YAML.dump(data_set)
rescue Errno::ECONNREFUSED => e
  sleep(60)
  retry
end


