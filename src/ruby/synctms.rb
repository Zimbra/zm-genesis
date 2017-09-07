#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# This program will synchronized TMS database with build server.
# libxml2 is required for faster xml processing
#
require 'rubygems'

require 'getoptlong'
require 'log4r'
require 'net/http'
require 'pg'
require 'uri'
require 'xml'
require 'yaml'

include Log4r

module Sync

  MESSAGES =<<DATA
syntms

sync tms database

   -h this message
   --server url of the build server, default to %s
   --tms hostname of tms, default to %s
   --verbose more verbose output
DATA

  #Logger setup
  Logger = Logger.new 'reportlog'
  Logger.outputters = StdoutOutputter.new 'console',
  :formatter => PatternFormatter.new(:pattern => "%M")
  Logger.level = INFO
  Logger.level = DEBUG if $DEBUG

  @unit_test = false
  @buildurl = 'http://zre-matrix.eng.vmware.com/links'
  @tms = ENV['tms'] || 'zqa-tms.eng.vmware.com' #use environment varialable if one is available
  @db = 'tms_production'
  @norun = false
  #bypass proxy
  ENV.delete('http_proxy')
  ENV.delete('HTTP_PROXY')


  def Sync.getOptions
    [
     ['-h', GetoptLong::NO_ARGUMENT],
     ['--norun',  GetoptLong::NO_ARGUMENT],
     ['--server', GetoptLong::OPTIONAL_ARGUMENT],
     ['--test', GetoptLong::NO_ARGUMENT],
     ['--tms', GetoptLong::OPTIONAL_ARGUMENT],
     ['--verbose', GetoptLong::NO_ARGUMENT]
    ]
  end

  def Sync.printHelp
    Logger.info MESSAGES%[@buildurl, @tms]
  end

  #List of directories with link structure
  class Directory
    attr_accessor :link, :name
  end

  class Branch
    attr_accessor :name, :id
    DBNAME = 'branches'
    
    def sqlInsert
      nowTime = Time.now
       "INSERT INTO %s (name, created_on, updated_on) SELECT '%s', '%s', '%s'  "%[DBNAME, name, nowTime, nowTime] +
        "WHERE NOT EXISTS (SELECT * from %s WHERE name = '%s'); "%[DBNAME, name]
    end

  end

  class OS
    attr_accessor :name, :id
    DBNAME = 'architectures'

    def sqlInsert
      nowTime = Time.now
      "INSERT INTO %s (name, created_on, updated_on) SELECT '%s', '%s', '%s'  "%[DBNAME, name, nowTime, nowTime] +
        "WHERE NOT EXISTS (SELECT * from %s WHERE name = '%s'); "%[DBNAME, name]
    end
  end

  def Sync.getID(entity, pgconn)
    begin
      statement = entity.sqlID rescue "SELECT id from %s where name = '%s';"%[entity.class.const_get('DBNAME'), entity.name]
      Logger.debug("Sync.getID statement '%s'"%statement)
      result = pgconn.exec(statement)
      Logger.debug("Sync.getID result %s"%result)
      resulta = result.to_a
      id = resulta.first["id"].to_i unless resulta.first.nil?
      Logger.info(" Sync.getID multiple id found, use the first %s %s"%[YAML.dump(entity), YAML.dump(result.to_a)]) if result.to_a.size > 1
      result.clear
    rescue => e
      Logger.info(e)
      id = nil
    end
    id
  end

  def Sync.insertDB(entityList, pgconn)
    [*entityList].map do |x|
      x.sqlInsert
    end.each  do |y|
      Logger.debug("insertDB %s"%y)
      unless(@norun)
        pgconn.exec(y)
      end
    end
    [*entityList].each do |y|
      y.id = getID(y, pgconn)
    end
    entityList
  end

  def Sync.updateDB(entityList, pgconn)
    [*entityList].map do |x|
      x.sqlUpdate
    end.each  do |y|
      Logger.debug("updateDB %s"%y)
      unless(@norun)
        pgconn.exec(y)
      end
    end
    entityList
  end



  class Build
    attr_accessor :branch, :name, :os, :note, :id
    attr_reader :baseURL
    DBNAME = 'builds'
    
    def initialize(urlString = nil, pbaseURL = 'http://zre-matrix.eng.vmware.com/links/')
      if(urlString.nil?)
        Logger.debug('Building class Build with nil urlString')
      else
        Logger.debug("Building class Build based on '%s'"%urlString)
      end
      @baseURL = pbaseURL
      self.os, self.branch, self.name = parse(urlString, baseURL) unless urlString.nil?
    end

    def sqlInsert
      nowTime = Time.now
      if(note.nil?)
        "INSERT INTO %s (name, created_on, updated_on, branch_id, architecture_id) SELECT '%s', '%s', '%s', %s, %s "%[DBNAME, name, nowTime, nowTime, branch.id, os.id] +
          "WHERE NOT EXISTS (SELECT * from %s WHERE name = '%s' and branch_id = %s and architecture_id = %s); "%[DBNAME, name, branch.id, os.id]
      else
        "INSERT INTO %s (name, created_on, updated_on, branch_id, architecture_id, note) SELECT '%s', '%s', '%s', %s, %s, '%s' "%[DBNAME, name, nowTime, nowTime, branch.id, os.id, note] +
          "WHERE NOT EXISTS (SELECT * from %s WHERE name = '%s' and branch_id = %s and architecture_id = %s); "%[DBNAME, name, branch.id, os.id]
      end
    end

    def sqlID
      "SELECT id from %s where name = '%s' and branch_id = %s and architecture_id = %s;"%[DBNAME, name, branch.id, os.id]
    end

    def sqlUpdate
      "UPDATE %s set note = '%s' where name = '%s' and branch_id = %s and architecture_id = %s;"%[DBNAME, note, name, branch.id, os.id]
    end

    def noteURL
      osLink, branchLink, nameLink =  [(os.name rescue os) || '',
                                       (branch.name rescue branch) || '',
                                       name].map do |x| Sync.normalize(x) 
      end
      URI.join(baseURL, osLink, branchLink, nameLink, 'RELEASED')
    end

    def parse(urlString, baseURL)
      matcher = Regexp.new("^%s([^/]*)/([^/]*)/([^/]*)"%Sync.normalize(baseURL))
      splitURL = matcher.match(urlString)
      if(splitURL)
        splitURL[1..3]
      else
        [nil, nil, nil]
      end
    end
    
    def Build.transformOS(buildList, osList)
      buildList.map do |x|
        mSelect = osList.select {|y| x.os == y.name }.first
        x.os = mSelect unless mSelect.nil?
        x
      end
    end

    def Build.transformBranch(buildList, branchList)
      buildList.map do |x|
        mSelect = branchList.select {|y| x.branch == y.name}.first
        x.branch = mSelect unless mSelect.nil?
        x
      end
    end
  end

  #Given a url, this function returns list of links
  def Sync.getDirectories(urlLink, filter = [], whitelist = nil)
    Logger.debug('Sync.getDirectories: link is %s'%urlLink)
    urlLink = normalize(urlLink)
    parser = XML::HTMLParser.file(urlLink.to_s)
    doc = parser.parse
    GC.start
    Logger.debug("Sync.getDirectories parse doc is\n%s"%doc)
    Logger.debug("Sync.getDirectories xpath extraction")
    doc.find("//*/a[@href!='/']").map do |node|  #looking for a form of <a href="F11_64/">F11_64/</a>
      #node.attributes.first.value  # interested in value
      Logger.debug(' %s'%node.content)
      node.content
    end.uniq.select do |node| #only in one that ends in /
      node =~ /\/$/ && ![*filter].any? do |x|
        node == normalize(x)
      end && #white list
        (whitelist.nil? || [*whitelist].any? do |y|
           node.include?(y)
         end)
    end.map do |node| #transform to directories
      dir = Directory.new
      dir.link = URI.join(urlLink, node)
      dir.name = node
      dir
    end
  end

  #Given a url, this function returns list of builds
  def Sync.getBuildList(urlLink, buildFilter = nil)
    applyArray = [
                  ['WINDOWS', buildFilter].compact,
                  [%w(32B CRAY CRAY2 D2 EDISON FRANK FRANKLIN_D1 FRANKLIN_D2 FRANKLIN_D3 FRANKLIN_D4 FRANKLIN_D5)],
                  [%w(latest)],
                  [[],%w(ZimbraBuild)],
                  [[], %w(i386 x86_64 ppc amd64)],
                 ]
    directories = nil
    applyArray.each do|logic|
      if(directories.nil?)
        directories = getDirectories(urlLink, *logic)
      else
        directories = directories.map do |list|
          Logger.debug("Sync.getBuildList: recursive call %s"%list.link.to_s)
          getDirectories(list.link.to_s, *logic)
        end.flatten
      end
    end
    #Transform to list of builds
    directories.map do |directory|
      Build.new(directory.link.to_s, urlLink)
    end
  end

  #Build unique list of class
  # mapping {:from => :accessor, :to => :accessor}
  def Sync.buildUniqueObjects(list, workClass, mapping)
    list.map do |x|
      x.send(mapping[:from])
    end.uniq.map do |y|
      item = workClass.new
      item.send(mapping[:to], y)
      item
    end
  end

  # normailzed href url..always have '/' in the end
  def Sync.normalize(url)
    workURL = url
    workURL = workURL + '/' unless workURL =~ /\/$/
    workURL
  end

  def Sync.getOSnBranch(list, pgconn = nil)
    result = [[OS, :os], [Branch, :branch]].map do |x|
      buildUniqueObjects(list, x.first, {:from => x[1], :to => :name=}) 
    end
    if(pgconn)
      result = result.map do |objectList|
        objectList.each do |curObject|
          curObject.id = getID(curObject, pgconn)
        end
      end
    end
    result
  end

  def Sync.getBuildID(list, pgconn)
    list.map do |x|
      x.id = getID(x, pgconn)
      x
    end
  end

  def Sync.getNotes(list)
    list.each do |x|
      url = x.noteURL
      Logger.debug("Sync.getNotes url %s"%YAML.dump(url))
      req = Net::HTTP::Get.new(url.path)
      res = Net::HTTP.start(url.host, url.port) do |http|
        http.request(req)
      end
      Logger.debug("Sync.getNotes response %s"%YAML.dump(res.body))
      unless res.body.include?('404 Not Found') 
        x.note = res.body.chomp
      end
      Logger.debug("Sync.getnote note '%s'"%x.note)
    end
    list
  end

  begin
    ::GetoptLong.new(*getOptions).each do | opt, arg|
      case opt
      when '-h' then 
        printHelp
        exit
      when '--norun' then
        @norun = true
      when '--server' then
        @buildurl = arg
      when '--verbose' then
        Logger.level = DEBUG
      when '--test' then
        @unit_test = true
      when '--tms' then
        @tms = arg  
      end  

    end
  rescue  GetoptLong::InvalidOption
    printHelp
    exit
  end

  if(!@unit_test)  
    Logger.info("Contact %s to get available builds"%@buildurl)
    buildList = Sync.getBuildList(@buildurl)
    pgconn = PGconn.connect(:dbname =>  @db, :host => @tms, :user => 'postgres', :password => 'zimbra')
    osList, branchList = Sync.getOSnBranch(buildList, pgconn)
    #update database
    [osList, branchList].each do |mList|
      mList.select {|x| x.id.nil?}.each do |y|
        insertDB(y, pgconn)
      end
    end
    #merge os, branch objects into build objects
    buildList = Build.transformOS(Build.transformBranch(buildList, branchList), osList)
    #grab notes
    buildList = getNotes(buildList)
    #grab buildID
    buildList = getBuildID(buildList, pgconn)
    newBuild = buildList.select {|x| x.id.nil?}
    remainBuild = buildList - newBuild
    Logger.info("Add new builds to TMS, %s, %s rows %s"%[@tms, @db, newBuild.size])
    insertDB(newBuild, pgconn)
    Logger.info("Modify notes if necessary size %s"%remainBuild.size)
    updateDB(remainBuild, pgconn)
    pgconn.finish rescue nil
    exit
  end

  Logger.info("Start Unit Testing")
  require 'test/unit'

  class TestCaseTest < Test::Unit::TestCase

    def test_sql_statement
      os = OS.new
      os.name = "hi"
      assert(os.sqlInsert.include?(os.name))
      branch = Branch.new
      branch.name = "there"
      branch.name = "where"
      assert(branch.sqlInsert.include?(branch.name))
    end

    def test_directory
      test = Directory.new
      test.link = 'hi'
      test.name = 'see'
      assert(test.link == 'hi')
      assert(test.name == 'see')
    end
    
    def test_getdiretories
      #Sync.getDirectories('http://zre-matrix.eng.vmware.com/links/SLES10_64/main/20101130000101_NETWORK/ZimbraBuild/', [], %w(i386 x86_64 ppc amd64)).each {|i| puts YAML.dump(i.link.to_s) }
    end

    def test_getbuildlist
      #Sync.getBuildList('http://zre-matrix.eng.vmware.com/links/', 'SLES10_64').each {|i| puts YAML.dump(i) }
    end

    def test_getosbranch
      directories = Sync.getBuildList('http://zre-matrix.eng.vmware.com/links/', 'SLES10_64')
      oslist, branchList = Sync.getOSnBranch(directories)
      puts YAML.dump(oslist)
      puts YAML.dump(branchList)
      assert(oslist.first.name == 'SLES10_64')
      assert(branchList.size > 0)
    end

#   def test_transformbuild_with_pg
#       pgconn = PGconn.connect(:dbname => 'tms_development', :host => 'zqa-tms.eng.vmware.com', :user => 'postgres', :password => 'zimbra')
#       directories = Sync.getBuildList('http://zre-matrix.eng.vmware.com/links/', 'SLES10_64')
#       oslist, branchlist = Sync.getOSnBranch(directories, pgconn)
#       emptyOS = oslist.select {|x| x.id.nil?}
#       emptyBranch = branchlist.select {|x| x.id.nil?}
#       emptyOS.map {|x| Sync.insertDB(x, pgconn) }
#       emptyBranch.map {|x| Sync.insertDB(x, pgconn) }
#       buildList = Sync.getBuildID(Build.transformOS(Build.transformBranch(directories, branchlist), oslist), pgconn)
#       puts YAML.dump(buildList)
#       buildList = Sync.getNotes(buildList)
#       #the build without id is new
#       newBuild = buildList.select {|x| x.id.nil?}
#       remainBuild = buildList - newBuild

#       puts "New Builds"
#       puts YAML.dump(newBuild)
#       Sync.insertDB(newBuild, pgconn)

#       puts "Update Builds"
#       puts YAML.dump(remainBuild)
#       Sync.updateDB(remainBuild, pgconn)
#       pgconn.finish
#     end

    def test_insertDB
      pgconn = PGconn.connect(:dbname => 'tms_development', :host => 'zqa-tms.eng.vmware.com', :user => 'postgres', :password => 'zimbra')
      os = OS.new
      os.name = "yadayada"
      os = Sync.insertDB(os, pgconn)
      pgconn.finish
      assert(os.id == 85)
    end


    def test_build_nourl
      test = Build.new
      assert(test.name.nil?)
      assert(test.branch.nil?)
      assert(test.os.nil?)
      assert(test.note.nil?)
      assert(test.baseURL == 'http://zre-matrix.eng.vmware.com/links/')
    end

    def test_build_someurl
      test = Build.new('http://zre-matrix.eng.vmware.com/links/SLES10_64/main/20101130000101_NETWORK/ZimbraBuild/')
      assert(test.name == '20101130000101_NETWORK')
      assert(test.os == 'SLES10_64')
      assert(test.branch == 'main')
      assert(test.note.nil?)
    end

    def test_build_empty
      test = Build.new('')
      assert(test.name.nil? && test.os.nil? && test.branch.nil? && test.note.nil?)
    end

    def test_base_url
      test = Build.new('', 'hi')
      assert(test.baseURL == 'hi')
    end

    def test_normalize_no_trailing
      url = 'http://hi'
      result = Sync.normalize(url)
      assert(url == 'http://hi')
      assert(result == 'http://hi/')
    end

    def test_normalize_trailing
      url = 'http://hi/'
      result = Sync.normalize(url)
      assert(url == 'http://hi/')
      assert(result == 'http://hi/')
    end

    def test_parse
      test = Build.new
      result = test.parse('http://zre-matrix.eng.vmware.com/links/SLES10_64/main/20101130000101_NETWORK/ZimbraBuild', 
                      'http://zre-matrix.eng.vmware.com/links/')
      assert(result == ['SLES10_64', 'main', '20101130000101_NETWORK'])
    end

    def test_parse_no_trailing
      test = Build.new
      result = test.parse('http://zre-matrix.eng.vmware.com/links/SLES10_64/main/20101130000101_NETWORK/ZimbraBuild', 
                      'http://zre-matrix.eng.vmware.com/links')
      assert(result == ['SLES10_64', 'main', '20101130000101_NETWORK'])
    end

    def test_parse_empty_header
      test = Build.new
      result = test.parse('http://zre-matrix.eng.vmware.com/links/SLES10_64/main/20101130000101_NETWORK/ZimbraBuild', '')
      assert(result.all? {|x| x.nil? })
    end

    def test_build_unique_object
      myList = %w(hi there this is me)
      result = Sync.buildUniqueObjects(myList, Branch, {:from => :to_str, :to => :name= })
      assert(result.all? {|x| x.class == Sync::Branch})
      assert(result.map {|x| x.name} == myList)
    end

    def test_build_duplicates
      myList = %w(hi there this me is me)
      myListU = myList.uniq
      result = Sync.buildUniqueObjects(myList, Branch, {:from => :to_str, :to => :name= })
      assert(result.all? {|x| x.class == Sync::Branch})
      assert(result.map {|x| x.name} == myListU)
    end

    def test_build_insert
      mBuild = Build.new
      mOS = OS.new
      mOS.name = 'F11'
      mBranch = Branch.new
      mBranch.name = "main"
      mOS.id = 23
      mBranch.id = 45
      mBuild.os = mOS
      mBuild.branch = mBranch
      mBuild.name = 'hi'
      assert(mBuild.sqlInsert.include?('hi'))
    end

    def test_build_update
      mBuild = Build.new
      mOS = OS.new
      mOS.name = 'F11'
      mBranch = Branch.new
      mBranch.name = "main"
      mOS.id = 23
      mBranch.id = 45
      mBuild.os = mOS
      mBuild.branch = mBranch
      mBuild.name = 'hi'
      mBuild.note = 'mynote'
      assert(mBuild.sqlUpdate.include?('mynote'))
    end

    def test_build_noteuri
      mBuild = Build.new
      mOS = OS.new
      mOS.name = 'F11'
      mBranch = Branch.new
      mBranch.name = "main"
      mOS.id = 23
      mBranch.id = 45
      mBuild.os = mOS
      mBuild.branch = mBranch
      mBuild.name = 'hi'
      assert(mBuild.noteURL.to_s.include?('RELEASED'))
    end
  end

end
