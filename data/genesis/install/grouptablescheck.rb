#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2007 Zimbra
#
#

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model" 
require "action/block"
require "action/runcommand" 
require "action/verify"
#require "action/zmcontrol" 

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "group tables test"

include Action 


expected = {'mail_item' => {'metadata' => 'mediumtext',
                            'size' => 'bigint'
                           },
            'revision' => {'size' => 'bigint'}
           }
#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [       
  
  v(cb("Global config test") do
    res = {}
    expected.keys.each do |table|
      cmd = "--execute=\"select table_schema, data_type FROM information_schema.columns where table_name = \\\"#{table}\\\" AND ("
      cols = expected[table].keys.collect {|w| "column_name=\\\"#{w}\\\""}
      #puts "--execute=\"select table_schema, data_type FROM information_schema.columns where table_name = \\\"#{table}\\\" AND (#{cols.join(" OR ")})\\G\""
      mObject = RunCommand.new(File.join(Command::ZIMBRAPATH,'bin','mysql'),
                               Command::ZIMBRAUSER,
                               "--execute=\"select table_schema, column_name, data_type FROM information_schema.columns where table_name = \\\"#{table}\\\" AND (#{cols.join(" OR ")})\\G\"")
      mResult = mObject.run
      result = mResult[1]
      #puts result
      if(result =~ /Data\s+:/)
        result = result[/Data\s+:(.*?)\s*\}/m, 1]
      end
      result = result.split("\n").select {|w| w =~ /.*(table_schema|column_name|data_type).*/}.collect {|w| w.split(/:\s+/)[1].chomp.strip}
      res[table] = {}
      i = 0
      while i < result.length
        res[table][result[i]] = {}
        for j in 0..expected[table].length - 1
          res[table][result[i]][result[i + j * 3 + 1]] = result[i + j * 3 + 2]
        end
        i += expected[table].length * 3
      end
    end
    [0, res]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].keys.select do |table|
      !data[1][table].keys.select { |k| data[1][table][k] != expected[table]}.compact.empty?
    end.compact.empty?
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {}
      data[1].keys.select do |table|
        mcaller.badones['table ' + table] = Hash[*data[1][table].keys.select do |k|
            data[1][table][k] != expected[table]
          end.collect do |k|
            [k, Hash[*expected[table].keys.select do |col|
                        data[1][table][k][col] != expected[table][col]
                      end.collect do |col|
                        [col, {"IS"=>data[1][table][k][col], "SB"=>expected[table][col]}]
                      end.flatten]
            ]
          end.flatten
        ]
      end
      mcaller.badones.delete_if {|key, value| value == {}}
    end
  end,

]
    	

#
# Tear Down
#
current.teardown = [         
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end 
