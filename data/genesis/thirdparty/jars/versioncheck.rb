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

mypath = 'data'
if($0 =~ /data\/genesis/)
  mypath += '/genesis'
end

require "model" 
require "action/block"
require "action/runcommand" 
require "action/verify"
require "action/buildparser" 
require "model/deployment"
require "action/oslicense"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Jar versions test"

include Action 

#(mCfg = ConfigParser.new()).run
allHosts = Model::Deployment.getAllServers()
isRelease = (theBuild = RunCommand.new('grep', 'root', 'zimbra-core', File.join(Command::ZIMBRAPATH, '.install_history')).run[1].split(/\n/).last) =~ /GA/

class VersionExtractor < Action::Command
  attr :archive, false
  attr :versionfile, false
  attr :versionpattern, false
  #
  # Objection creation
  # 
  def initialize(filename = File.join('lib', 'jars', 'lucene*.jar'), versionFile = File.join('META-INF', 'MANIFEST.MF'),
                 pattern = %r/.*[Ii]mplementation-[Vv]ersion:\s+(\S+)\s*.*$/)
    super()
    @versionfile = versionFile
    @archive = File.join(Command::ZIMBRAPATH, filename)
    @extractor = pattern
  end
   
  #
  # Execute  action
  # filename is stored inside @archive at object initilization time 
  def run 
    begin
      mResult = RunCommand.new('/bin/ls', 'root', @archive, '2>&1').run
      mResult[1] = mResult[1].strip.chomp
      return mResult if mResult[0] != 0
      crtArchive = mResult[1]
      mResult = RunCommand.new('cd', Command::ZIMBRAUSER, Command::ZIMBRATMPPATH, ';jar','-xvf', 
                               crtArchive, @versionfile).run
      if mResult[1].nil?
        mResult[0] += 1 
        mResult[1] = "File #{@versionfile} missing from archive #{@archive}[#{crtArchive}]"
      end
      return mResult if mResult[0] != 0
      mResult[1] = mResult[1].strip.chomp
      mResult = RunCommand.new('cd', 'root', Command::ZIMBRATMPPATH, ';/bin/cat', versionfile).run
      mResult[1] = mResult[1].strip.chomp
      return mResult if mResult[0] != 0
      result = mResult[1][/#{@extractor}/, 1]
      [0, result]
    rescue
      [1, 'Unknown']
    end
  end
  
  def to_str
    "Action:VersionExtractor archive:#{@archive}, version file:#{@versionfile}"
  end   
end


expected = {
            '^ant-.*-ziputil.*'      => {'approved' => '1.7.0',
                                         'proc' => Proc.new() do |ar|
                                                     ver = VersionExtractor.new(File.join('lib', 'jars', File.basename(ar)),
                                                                                File.join('META-INF', 'MANIFEST.MF'),
                                                                                '^Ant-Version:\s+Apache\s+Ant\s+(\S+)\s*.*$').run
                                                     ver.last
                                                   end
                                        },
            '^antlr-.*'              => {'approved' => '3.2', #bug 67353
                                         'proc' => Proc.new() do |ar|
                                                     ver = VersionExtractor.new(File.join('lib', 'jars', File.basename(ar)),
                                                                                File.join('META-INF', 'maven', 'org.antlr', 'gunit', 'pom.properties'),
                                                                                '^version=(\S+).*$').run
                                                     ver.last
                                                   end
                                        },
            '^apache-cassandra-\d.*' => {'approved' => '1.0.8',  #bug 71812, 67353, 67356
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },
            '^apache-cassandra-t.*'  => {'approved' => '1.0.8',  #bug 71812, 58590, 67353, 67356
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },
            '^apache-jsieve.*'       => {'approved' => '0.5',
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },
            '^apache-log4j-extras-.*'=> {'approved' => '1.0', #bug 51197
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },
            '^asm-.*'                => {'approved' => '3.3.1', #bug 69734
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },
            '^bcprov-.*'             => {'approved' => '1.46.0', #bug 59393
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },
            '^commons-cli.*'         => {'approved' => '1.2',
                                         'proc' => Proc.new() do |ar|
                                                     ver = VersionExtractor.new(File.join('lib', 'jars', File.basename(ar)),
                                                                                'META-INF/maven/commons-cli/commons-cli/pom.properties',
                                                                                '^version=(\S+).*$').run
                                                     ver.last
                                                   end
                                        },
            '^commons-codec.*'       => {'approved' => OSL::LegalApproved['apache-commons-codec'], #bug 82719
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },
            '^commons-collections-.*'=> {'approved' => '3.2.2', #bug 58590
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },
                                          
            '^commons-compress-.*'=>    {'approved' => '1.10', 
                                          'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                         },                              
                                                                                
                                         
            '^commons-csv-.*'       => {'approved' => '1.2',
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },

                                        
            '^commons-dbcp-.*'       => {'approved' => '1.4', #bug 53255
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },
            '^commons-fileupload.*'  => {'approved' => '1.2.2', #bug 71631
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },
            '^commons-httpclient-.*' => {'approved' => '3.1', #bug 53255
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },
            '^commons-io.*'          => {'approved' => '1.4',
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },
            '^commons-lang-.*'       => {'approved' => '2.6', #bug 69545, 58590
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },
            '^commons-logging.*'     => {'approved' => '1.1.1', #bug 41554
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },
           # '^commons-net-.*'        => {'approved' => OSL::LegalApproved['commons-net'],
            #                             'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
             #                           },
                                        
              '^commons-net.*'        => {'approved' => '3.3', #bug 97635
                                          'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                         },
                             
                                        
            '^commons-pool.*'        => {'approved' => '1.6', #bug 71634
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },                                        
            '^concurrentlinkedhashmap-lru-.*' => {'approved' => '1.3.1', #bug 78025, 77568
                                                  'proc' => Proc.new() {|ar| ar[/concurrentlinkedhashmap-lru-(.*)\.jar/, 1]}
                                                 },
            '^curator-.*'        =>     {'approved' => OSL::LegalApproved['curator'] + '-incubating', #bug 82550
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },
            '^cxf-.*'                => {'approved' => OSL::LegalApproved['apache-cxf'], #bug 80416
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },
            '^dom4j-.*'              => {'approved' => '1.5.2',
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },
            '^ehcache-core.*'        => {'approved' => '2.5.1', #bug 65373, 69852
                                         'proc' => Proc.new() do |ar|
                                                     ver = VersionExtractor.new(File.join('lib', 'jars', File.basename(ar)),
                                                                                File.join('META-INF', 'maven', 'net.sf.ehcache', 'ehcache-core', 'pom.properties'),
                                                                                '^version=(\S+).*$').run
                                                     ver.last
                                                   end
                                        },
            '^ews_.*'                => {'approved' => OSL::LegalApproved['ews'],
                                         'proc' => Proc.new() {|ar| ar[/(ews_.*)\.jar/, 1]}
                                        },
            '^freemarker-.*'         => {'approved' => '2.3.19', #bug 75187
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },
            '^ganymed-ssh2-.*'       => {'approved' => 'build210', #bug 41554
                                         'proc' => Proc.new() {|ar| ar[/ganymed-ssh2-(.*)\.jar/, 1]}
                                        },
            '^guava.*'               => {'approved' => OSL::LegalApproved['guava'],
                                         'proc' => Proc.new() do |ar|
                                                     ver = VersionExtractor.new(File.join('lib', 'jars', File.basename(ar)),
                                                                                File.join('META-INF', 'maven', 'com.google.guava', 'guava', 'pom.properties'),
                                                                                '^version=(\S+).*$').run
                                                     ver.last
                                                   end
                                        },
            '^gmbal-api-only-.*'     => {'approved' => '2.2.6', #bug 74433
                                         'proc' => Proc.new() {|ar| File.basename(ar)[/gmbal-api-only-(.*)\.jar/, 1]}
                                        },
            '^hadoop-core-.*'        => {'approved' => '1.0.0', #bug 71896
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },
            '^hbase-.*'              => {'approved' => '0.92.1', #bug 71898
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },
            '^hector-core-.*'         => {'approved' => '1.0-4-SNAPSHOT', #bug 72574
                                         'proc' => Proc.new() do |ar|
                                                     ver = VersionExtractor.new(File.join('lib', 'jars', File.basename(ar)),
                                                                                File.join('META-INF', 'maven', 'me.prettyprint', 'hector-core', 'pom.properties'),
                                                                                '^version=(\S+).*$').run
                                                     ver.last
                                                   end
                                        },
            '^helix-core-.*'         => {'approved' => OSL::LegalApproved['apache-helix'] + '-incubating',
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },
            '^high-scale-lib-.*'     => {'approved' => '1.1.2', #bug 58590
                                         'proc' => Proc.new() {|ar| ar[/high-scale-lib-(.*)\.jar/, 1]}
                                        },
            '^httpasyncclient-.*'    => {'approved' => OSL::LegalApproved['apache-httpasyncclient'],
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },
            '^httpclient-.*'         => {'approved' => OSL::LegalApproved['httpclient'],
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },
            '^httpcore-.*'           => {'approved' => OSL::LegalApproved['apache-httpcomponents-core'], #bug 80416
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },
            '^ical4j-.*'             => {'approved' => '0.9.16-patched', #bug 50398
                                         'proc' => Proc.new() {|ar| ar[/ical4j-(.*)\.jar/, 1]}
                                        },
            '^icu4j.*'               => {'approved' => '4.8.1.1',
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },
            '^jackson.*'             => {'approved' => '1.9.2',
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },
            '^jamm-.*'               => {'approved' => '0.2.5', #bug 71812, 67353
                                         'proc' => Proc.new() {|ar| ar[/jamm-(.*)\.jar/, 1]}
                                                   #Proc.new() do |ar|
                                                   #  ver = VersionExtractor.new(File.join('lib', 'jars', File.basename(ar)),
                                                   #                             File.join('META-INF', 'maven', 'com.github.stephenc', 'jamm', 'pom.properties'),
                                                   #                             '^version=(\S+).*$').run
                                                   #  ver.last
                                                   #end
                                        },
            '^javamail-.*'           => {'approved' => '1.4.5', #bug 72323, 71379
                                         'proc' => Proc.new() do |ar|
                                                     ver = VersionExtractor.new(File.join('lib', 'jars', File.basename(ar)),
                                                                                File.join('META-INF', 'maven', 'javax.mail', 'mail', 'pom.properties'),
                                                                                '^version=(\S+).*$').run
                                                     if ver.first != 0
                                                       ver = VersionExtractor.new(File.join('lib', 'jars', File.basename(ar)),
                                                                                File.join('META-INF', 'maven', 'com.sun.mail', 'javax.mail', 'pom.properties'),
                                                                                '^version=(\S+).*$').run
                                                     end
                                                     ver.last
                                                   end
                                        },
            '^JavaPNS_.*'            => {'approved' => OSL::LegalApproved['JavaPNS'],
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },
            'javax.ws.rs-api-.*'     => {'approved' => OSL::LegalApproved['javax.ws.rs-api'], #bug 86400
                                         'proc' => Proc.new() do |ar|
                                                     ver = VersionExtractor.new(File.join('lib', 'jars', File.basename(ar)),
                                                                                File.join('META-INF', 'MANIFEST.MF'),
                                                                                '^Specification-Version:\s+(\S+)\s*.*$').run
                                                     ver.last
                                                   end
                                        },
            '^jaxb-api-.*'           => {'approved' => '2.2.6', #bug 74433
                                         'proc' => Proc.new() do |ar|
                                                     ver = VersionExtractor.new(File.join('lib', 'jars', File.basename(ar)),
                                                                                File.join('META-INF', 'maven', 'javax.xml.bind', 'jaxb-api', 'pom.properties'),
                                                                                '^version=(\S+).*$').run
                                                     ver.last
                                                   end
                                        },
            '^jaxb-impl-.*'          => {'approved' => '2.2.6', #bug 74433
                                         'proc' => Proc.new() do |ar|
                                                     ver = VersionExtractor.new(File.join('lib', 'jars', File.basename(ar)),
                                                                                File.join('META-INF', 'MANIFEST.MF'),
                                                                                '^Specification-Version:\s+(\S+)\s*.*$').run
                                                     ver.last
                                                   end
                                        },
            '^jaxen-.*'              => {'approved' => '1.1.3', #bug 71818
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },
            '^jaxws-api-.*'          => {'approved' => '2.2.8', #bug 74433, Quanah says it's really 2.2.6
                                         'proc' => Proc.new() do |ar|
                                                     ver = VersionExtractor.new(File.join('lib', 'jars', File.basename(ar)),
                                                                                File.join('META-INF', 'maven', 'javax.xml.ws', 'jaxws-api', 'pom.properties'),
                                                                                '^version=(\S+).*$').run
                                                     ver.last
                                                   end
                                        },
            '^jaxws-rt-.*'           => {'approved' => '2.2.6', #bug 74433
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },
            '^jcommon-.*'            => {'approved' => OSL::LegalApproved['jcommon'],
                                         'proc' => Proc.new() {|ar| ar[/jcommon-(.*)\.jar/, 1]}
                                        },
            'jcharset.*'             => {'approved' => 'APPROVED', # bug 44587
                                         'proc' => Proc.new() {|ar| 'APPROVED'}
                                        },
            '^jcs-.*'                => {'approved' => '1.3', #bug 69253
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },
            '^jdom.*'                => {'approved' => '1.1.1', #bug 41554
                                         'proc' => Proc.new() do |ar|
                                                     ver = VersionExtractor.new(File.join('lib', 'jars', File.basename(ar)),
                                                                                File.join('META-INF', 'jdom-info.xml'),
                                                                                '<version>([^\s,]+).*$').run
                                                     ver.last
                                                   end
                                        },
            '^jersey-[^m].*'         => {'approved' => '1.11',
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },
            '^jersey-multipart.*'    => {'approved' => '1.12', #bug 73213
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },
             '^jetty-.*'             => {'approved' => OSL::LegalApproved['jetty'],
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },
             '^jfreechart-.*'        => {'approved' => OSL::LegalApproved['jfreechart'],
                                         'proc' => Proc.new() {|ar| File.basename(ar)[/jfreechart-(.*)\.jar/, 1]}
                                        },
             '^jna-.*'               => {'approved' => '3.4.0', #bug 72558
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },
             '^jsr181-api-.*'        => {'approved' => '2.2.6', #bug 74433
                                         'proc' => Proc.new() {|ar| File.basename(ar)[/jsr181-api-(.*)\.jar/, 1]}
                                        },
             '^jsr311-api-.*'        => {'approved' => '1.1.1', #bug 69957
                                         'proc' => Proc.new() do |ar|
                                                     ver = VersionExtractor.new(File.join('lib', 'jars', File.basename(ar)),
                                                                                File.join('META-INF', 'maven', 'javax.ws.rs', 'jsr311-api', 'pom.properties'),
                                                                                '^version=(\S+).*$').run
                                                     ver.last
                                                   end
                                        },
                                       #URL: http://code.google.com/p/junixsocket/wiki/GettingStarted
                                       #     1. Download the binary and/or source tarball from the Downloads page
                                       #     2. Extract the files somewhere
                                       #           tar xvjf junixsocket-X.Y-bin.tar.bz2
                                       #           tar xvjf junixsocket-X.Y-src.tar.bz2
                                       #          (where X.Y stands for the version number, e.g. 1.2)
             '^junixsocket-.*'       => {'approved' => '1.3',
                                         'proc' => Proc.new() do |ar|
                                                     mResult = RunCommand.new('ls', 'root', File.join(Command::ZIMBRAPATH, 'lib', 'jars', File.basename(ar))).run
                                                     mResult[1][/-([\d\.]+)\.jar/, 1]
                                                   end
                                        },
             '^jython-.*'            => {'approved' => '2.5.2', #bug 77116
                                         'proc' => Proc.new() do |ar|
                                                     ver = VersionExtractor.new(File.join('lib', 'jars', File.basename(ar)),
                                                                                File.join('META-INF', 'MANIFEST.MF'),
                                                                                '^[Vv]ersion:\s+(\S+)\s*.*$').run
                                                     ver.last
                                                   end
                                        },
             '^jzlib-?.*'            => {'approved' => '1.0.7', #bug 63175, 77082
                                         'proc' => Proc.new() do |ar|
                                                     # disable this approach for now - in 1.0.7 JZLib.version is reported as 1.0.2
                                                     if false
                                                       verDumper = 'Version'
                                                       verClass = 'import com.jcraft.jzlib.JZlib;\n' +
                                                                  'public class Version {\n' +
                                                                  '  public static void main(String [] args) {\n' +
                                                                  '    System.out.println(JZlib.version());\n' +
                                                                  '  };\n' +
                                                                  '}'
                                                       RunCommand.new('/bin/rm', 'root', '-rf', File::join('', 'tmp', "#{verDumper}.*")).run
                                                       RunCommand.new('echo', Command::ZIMBRAUSER, '-e', "\"#{verClass}\" > #{File::join('', 'tmp', verDumper)}.java").run
                                                       RunCommand.new('cd /tmp; javac', Command::ZIMBRAUSER, '-cp ',  ar, "#{verDumper}.java").run
                                                       mResult = RunCommand.new('zmjava ', Command::ZIMBRAUSER, 
                                                                                '-cp', File::join('', 'tmp'), verDumper).run
                                                       mResult[1].chomp
                                                     else
                                                       ver = VersionExtractor.new(File.join('lib', 'jars', File.basename(ar)),
                                                                                File.join('META-INF', 'maven', 'com.jcraft', 'jzlib', 'pom.properties'),
                                                                                '^version=(\S+).*$').run
                                                       ver.last
                                                     end
                                                   end
                                        },
             '^libidn-.*'            => {'approved' => '1.24', #bug 71871
                                         'proc' => Proc.new() {|ar| File.basename(ar)[/libidn-(.*)\.jar/, 1]}
                                        },
             '^libthrift-.*'         => {'approved' => '0.6.1', #bug 58590, 67353
                                         'proc' => Proc.new() {|ar| ar[/libthrift-(.*)\.jar/, 1]}
                                        },
             '^log4j.*'              => {'approved' => '2.17.1', #bug 51197
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },
             '^lucene.*'             => {'approved' => '3.5.0', #bug 71946
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },
             '^mail'                 => {'approved' => '1.4.3',
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },
             '^mariadb-java-client-.*'           => {'approved' =>  OSL::LegalApproved['mariadb-java-client'],
                                         'proc' => Proc.new() do |ar|
                                                     ver = VersionExtractor.new(File.join('lib', 'jars', File.basename(ar)),
                                                                                File.join('META-INF', 'MANIFEST.MF'),
                                                                                'Bundle-Version:\s*(\S+)').run
                                                     ver.last
                                                   end
                                        },
             '^memcached.*'          => {'approved' => '2.6', #bug 71869
                                         'proc' => Proc.new() do |ar|
                                                     ver = VersionExtractor.new(File.join('lib', 'jars', File.basename(ar)),
                                                                                File.join('net', 'spy', 'memcached', 'build.properties'),
                                                                                'tree\.version=(\S+).*$').run
                                                     ver.last
                                                   end
                                        },
             '^mina-core.*'          => {'approved' => '2.0.4',
                                         'proc' => Proc.new() do |ar|
                                                     ver = VersionExtractor.new(File.join('lib', 'jars', File.basename(ar)),
                                                                                File.join('META-INF', 'maven', 'org.apache.mina', 'mina-core', 'pom.properties'),
                                                                                '^version=(\S+).*$').run
                                                     ver.last
                                                   end
                                        },
            # '^mysql-connector-java-.*'=> {'approved' => OSL::LegalApproved['mysql-connector-java'],
             #                              'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
              #                            },
             '^neethi-.*'            => {'approved' => OSL::LegalApproved['apache-neethi'], #bug 80416
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },
             '^nekohtml.*'           => {'approved' => '1.9.13', #bug 41554
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },
             '^noggit.*'             => {'approved' => OSL::LegalApproved['noggit'],
                                         'proc' => Proc.new() do |ar|
                                                     ver = VersionExtractor.new(File.join('lib', 'jars', File.basename(ar)),
                                                                                File.join('META-INF', 'maven', 'org.noggit', 'noggit', 'pom.properties'),
                                                                                '^version=(\S+).*$').run
                                                     ver.last
                                                   end
                                        },

             '^objenesis-.*'         => {'approved' => isRelease ? 'NOT DISTRIBUTED' : '1.2', #bug 59515, 63422 - Internal use only
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },
             '^perf4j-.*'            => {'approved' => '0.9.16', #bug 71881
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },
             '^policy-.*'            => {'approved' => '2.3.1', #bug 74433, Quanah says it's really 2.2.6
                                         'proc' => Proc.new() do |ar|
                                                     ver = VersionExtractor.new(File.join('lib', 'jars', File.basename(ar)),
                                                                                File.join('META-INF', 'maven', 'com.sun.xml.ws', 'policy', 'pom.properties'),
                                                                                '^version=(\S+).*$').run
                                                     ver.last
                                                   end
                                        },
             '^servlet-api.*'        => {'approved' => OSL::LegalApproved['servlet-api'], #bug 81861/2
                                         'proc' => Proc.new() do |ar|
                                                     ver = VersionExtractor.new(File.join('lib', 'jars', File.basename(ar)),
                                                                                File.join('META-INF', 'MANIFEST.MF'),
                                                                                'Bundle-Version:\s*(\S+)').run
                                                     ver.last
                                                   end
                                        },
             '^slf4j.*'              => {'approved' => '1.7.36', #bug 71882
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },
                                          
=begin                                        
             '^smack\..*'            => {'approved' => '3.2.1',
                                         'proc' => Proc.new() do |ar|
                                                     verDumper = 'Version'
                                                     verClass = 'import org.jivesoftware.smack.SmackConfiguration;\n' +
                                                                'public class Version {\n' +
                                                                '  public static void main(String [] args) {\n' +
                                                                '    System.out.println(SmackConfiguration.getVersion());\n' +
                                                                '  };\n' +
                                                                '}'
                                                     RunCommand.new('/bin/rm', 'root', '-rf', File::join('', 'tmp', "#{verDumper}.*")).run
                                                     RunCommand.new('echo', Command::ZIMBRAUSER, '-e', "\"#{verClass}\" > #{File::join('', 'tmp', verDumper)}.java").run
                                                     RunCommand.new('cd /tmp; javac', Command::ZIMBRAUSER, '-cp ',  ar, "#{verDumper}.java").run
                                                     mResult = RunCommand.new('zmjava ', Command::ZIMBRAUSER, 
                                                                              '-cp', File::join('', 'tmp'), verDumper).run
                                                     mResult[1].chomp
                                                   end
                                        },
=end                                     
                                        
                                        
             '^spring-.*'        => {'approved' => OSL::LegalApproved['spring-framework'] + '.RELEASE', #bug 81861/2
                                     'proc' => Proc.new() do |ar|
                                                 ver = VersionExtractor.new(File.join('lib', 'jars', File.basename(ar)),
                                                                            File.join('META-INF', 'MANIFEST.MF'),
                                                                            'Bundle-Version:\s*(\S+)').run
                                                 ver.last
                                               end
                                    },
             '^sqlite-jdbc.*'        => {'approved' => '3.7.5-1',
                                         'proc' => Proc.new() do |ar|
                                                     ver = VersionExtractor.new(File.join('lib', 'jars', File.basename(ar)),
                                                                                File.join('META-INF', 'maven', 'org.xerial', 'sqlite-jdbc', 'pom.properties'),
                                                                                '^version=(\S+).*$').run
                                                     ver.last
                                                   end
                                        },
             '^stax-ex-.*'           => {'approved' => '2.2.6', #bug 74433
                                         'proc' => Proc.new() {|ar| File.basename(ar)[/stax-ex-(.*)\.jar/, 1]}
                                        },
             '^stax2-.*'             => {'approved' => OSL::LegalApproved['stax2'], #bug 82313
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },
             '^streambuffer-.*'      => {'approved' => '1.4', #bug 74433, Quanah says it's really 2.2.6
                                         'proc' => Proc.new() do |ar|
                                                     ver = VersionExtractor.new(File.join('lib', 'jars', File.basename(ar)),
                                                                                File.join('META-INF', 'maven', 'com.sun.xml.stream.buffer', 'streambuffer', 'pom.properties'),
                                                                                '^version=(\S+).*$').run
                                                     ver.last
                                                   end
                                        },
             '^syslog4j-.*'          => {'approved' => '0.9.46', #bug 72558
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },
             '^tnef.*'               => {'approved' => OSL::LegalApproved['tnef'],
                                         'proc' => Proc.new() {|ar| ar[/tnef-(.*)\.jar/, 1]}
                                        },
             '^unboundid-ldapsdk-.*' => {'approved' => OSL::LegalApproved['unbound-ldap-sdk'],
                                         'proc' => Proc.new() do |ar|
                                                     mResult = RunCommand.new('zmjava', Command::ZIMBRAUSER, '-jar',
                                                                              File.join('lib', 'jars', File.basename(ar)), '2>&1').run
                                                     mResult[1][/Full Version String:\s+UnboundID LDAP SDK for Java\s+(\S+)/, 1]
                                                   end
                                        },
             '^woodstox-.*'          => {'approved' => OSL::LegalApproved['woodstox'], #bug 82313
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },
                                        
             '^owasp-.*'          => {'approved' => OSL::LegalApproved['owasp'], 
                                      'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                     },
  
                                        
             '^wsdl4j-.*'            => {'approved' => OSL::LegalApproved['wsdl4j'], #bug 80416
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },
                                          
                                        
                                        
=begin             
             '^xercesImpl.*'         => {'approved' => '2.9.1',
                                         'proc' => Proc.new() do |ar|
                                                     verDumper = 'MyVersion'
                                                     verClass = 'import org.apache.xerces.impl.Version;\n' +
                                                                'public class MyVersion {\n' +
                                                                '  public static void main(String [] args) {\n' +
                                                                '    System.out.println(Version.getVersion());\n' +
                                                                '  };\n' +
                                                                '}'
                                                     RunCommand.new('/bin/rm', 'root', '-rf', File::join('', 'tmp', "#{verDumper}.*")).run
                                                     RunCommand.new('echo', Command::ZIMBRAUSER, '-e', "\"#{verClass}\" > #{File::join('', 'tmp', verDumper)}.java").run
                                                     RunCommand.new('cd /tmp; javac', Command::ZIMBRAUSER, '-cp ',  ar, "#{verDumper}.java").run
                                                     mResult = RunCommand.new('zmjava ', Command::ZIMBRAUSER, 
                                                                              '-cp', File::join('', 'tmp'), verDumper).run
                                                     mResult[1].chomp.split.last
                                                   end
                                        },
=end
                                        
'^xercesImpl-.*'            => {'approved' => OSL::LegalApproved['xercesImpl'], #bug 80416
                                        'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                       },
                                
                                        
             '^xmlschema-.*'         => {'approved' => OSL::LegalApproved['xmlschema'], #bug 80416
                                         'proc' => Proc.new() do |ar|
                                                     ver = VersionExtractor.new(File.join('lib', 'jars', File.basename(ar)),
                                                                                File.join('META-INF', 'MANIFEST.MF'),
                                                                                'Bundle-Version:\s*(\S+)').run
                                                     ver.last
                                                   end
                                        },
             '^yuicompressor-.*'     => {'approved' => '2.4.2',
                                         'proc' => Proc.new() {|ar| File.basename(ar)[/yuicompressor-([^-]+)-.*/, 1]}
                                        },
             '^zkclient-.*'          => {'approved' => OSL::LegalApproved['zkclient'], #bug 82337/9
                                         'proc' => Proc.new() do |ar|
                                                     ver = VersionExtractor.new(File.join('lib', 'jars', File.basename(ar)),
                                                                                File.join('META-INF', 'maven', 'com.github.sgroschupf', 'zkclient', 'pom.properties'),
                                                                                '^version=(\S+).*$').run
                                                     ver.last
                                                   end
                                        },
             '^zookeeper-.*'         => {'approved' => OSL::LegalApproved['zookeeper'] + '-1392090', #bug 82337/9
                                         'proc' => Proc.new() {|ar| VersionExtractor.new(File.join('lib', 'jars', File.basename(ar))).run.last}
                                        },

              '^oauth-.*'         => {'approved' => OSL::LegalApproved['oauth'], #bug 82337/9
                                         'proc' => Proc.new() {|ar| File.basename(ar)[/oauth-(.*).jar/, 1]}
                                        },
              }
expected.default = {'approved' => 'LEGAL APPROVED',
                    'proc' => Proc.new() {|ar| 'NOT FOUND'}}
ignore = ['ant-.*', 'ews\..*', 'gifencoder\.jar', 'json\.jar', 'smackx.*', 'smack.jar', '(zm)?zimbra']

#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [
  v(cb("lib jars test") do
    res = {}
    mObject = RunCommand.new('ls', 'root', File.join(Command::ZIMBRAPATH, 'lib','jars', '*.jar'))
    mResult = mObject.run
    next mResult if mResult[0] != 0

    exitCode = 0
    illegal = []
    mResult[1].split(/\n/).compact.select {|w| File.basename(w) !~ /#{Regexp.compile(ignore.join('|'))}/}.each do |jar|
      keys = expected.keys.select {|k| File.basename(jar) =~ /#{k}/}
      if keys.length == 0
        illegal.push(jar)
        res[jar] = {'SB' => expected.default['approved'], 'IS' => 'NEW ADDITION'}
        next
      elsif keys.length != 1
        res[jar] = {'SB' => 'single regexp match', 'IS' => "[#{keys.join(', ')}]"}
        next
      else
        key = keys.first
      end
      if (found = expected[key]['proc'].call(jar)) != expected[key]['approved']
        res[jar] = {'SB' => expected[key]['approved'], 'IS' => found}
      end
    end
    [exitCode, res]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].empty?
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = data[1]
    end
  end,
  
  v(VersionExtractor.new('lib/jars/jakarta-oro*.jar')) do |mcaller, data|
    expected = 'No such file or directory'
    mcaller.pass = data[0] != 0 && data[1] =~ /#{expected}/
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'jakarta-oro version' => {"IS"=>data[1], "SB"=>expected}}
    end
  end,

  v(RunCommand.new('ls', 'root', File.join(Command::ZIMBRAPATH, 'lib', 'jars', 'java_memcached*.jar'))) do |mcaller, data|
    mcaller.pass = data[0] != 0# && data[1] =~ expected
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      if(data[1] =~ /Data\s+:/)
        data[1] = data[1][/Data\s+:\s+([^\s}].*?)$\s+\}/m, 1]
      end
      data[1] = data[1].strip.chomp
      mcaller.badones = {'java_memcached check' => {"IS"=>data[1], "SB"=>'missing'}}
    end
  end,

  v(VersionExtractor.new('lib/jars/mina-filter*.jar', 'META-INF/maven/org.apache.mina/mina-filter-ssl/pom.properties',
                         '^version=(\S+).*$')) do |mcaller, data|
    expected = 'No such file or directory'
    mcaller.pass = data[0] != 0 && data[1][/#{expected}/]
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'mina-filter version' => {"IS"=>data[1], "SB"=>expected}}
    end
  end,

  
=begin
   v(cb("oauth test") do
    res = {}
    exitCode = 0
    mFile = File.join(Command::ZIMBRAPATH, 'extensions-extra', 'oauth')
    stores = Model::Deployment.getServersRunning('store')
    allHosts.each do |host|
      if stores.include?(host)
        expected = ".*(\s+zimbra){2}.*#{mFile}"
      else
        expected = ".*No such file or directory.*"
      end
      mObject = RunCommandOn.new(host, 'ls', Command::ZIMBRAUSER,'-al', mFile, '2>&1')
      iResult = mObject.run
      if(iResult[1] =~ /Data\s+:/)
        iResult[1] = iResult[1][/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
      end
      if iResult[1][/#{Regexp.new(expected)}/].nil?
        res[host] = [iResult[1], expected]
        exitCode += 1
      end
    end
    [exitCode, res]
   end) do |mcaller, data|
    mcaller.pass = data[0] == 0
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true 
      end
      msgs = {}
      data[1].each_pair do |k, v|
        msgs[k] = {"IS"=>"#{v[0].split("\n")[0].strip()}", "SB"=>v[1]}
      end
      mcaller.badones = {File.join(Command::ZIMBRAPATH, 'extensions-extra', 'oauth') => msgs}
    end
   end,
=end

  v(cb("junit test") do
    res = {}
    exitCode = 0
    #expected = ".*No such file or directory.*"
    allHosts.each do |host|
      testDomain = Model::Domain.new(host[/[^.]+\.(.*)/, 1])
      myHost = Model::Host.new(host[/(.*)\.#{testDomain}/, 1], testDomain)
      mObject = RunCommandOn.new(myHost, 'find', 'root',
                                 Command::ZIMBRAPATH, '-name', '"junit*.jar"', '-print')
      iResult = mObject.run
      if(iResult[1] =~ /Data\s+:/)
        iResult[1] = iResult[1][/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
      end
      if !iResult[1].nil? && !iResult[1].empty?
        res[host] = [iResult[1], 'file(s) not found']
        exitCode += 1
      end
    end
    [exitCode, res]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true 
      end
      msgs = {}
      data[1].each_pair do |k, v|
        msgs[k] = {"IS"=>"#{v[0].split("\n")[0].strip()}", "SB"=>v[1]}
      end
      mcaller.badones = {'junit.jar test' => msgs}
    end
  end,
  
  if Model::Deployment.getServersRunning('store').include?(Model::TARGETHOST.to_s)
  [
    v(VersionExtractor.new(File.join('extensions-extra', 'openidconsumer', 'openid4java-[0-9]*.jar'))) do |mcaller, data|
      mcaller.pass = data[1] =~ /#{Regexp.escape(OSL::LegalApproved['org.openid4java'])}\b/
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {Model::TARGETHOST.to_s + ' - OpenID jar version' => {"IS" => data[1], "SB" => OSL::LegalApproved['org.openid4java']}}
      end
    end,
      
    v(VersionExtractor.new(File.join('jetty', 'webapps', 'service', 'WEB-INF', 'lib', 'objenesis-*.jar'))) do |mcaller, data|
      mcaller.pass = data[1] =~ /#{Regexp.escape(OSL::LegalApproved['objenesis'])}\b/
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {Model::TARGETHOST.to_s + ' - objenesis version' => {"IS" => data[1], "SB" => OSL::LegalApproved['objenesis']}}
      end
    end,
  ]
  end,

=begin
  v(cb("jain-sip-api test") do
    res = {}
    exitCode = 0
    mFile = File.join(Command::ZIMBRAPATH, 'zimlets-experimental', 'com_zimbra_asterisk.zip')
    mStore = mCfg.getServersRunning('store').first
    mObject = RunCommandOn.new(mStore, 'ls', Command::ZIMBRAUSER,'-al', mFile)
    iResult = mObject.run
    next [iResult[0], {mStore => [iResult[2], ".*(\s+zimbra){2}.*#{mFile}"]}] if iResult[0] != 0
    iResult = RunCommandOn.new(mStore, 'unzip', Command::ZIMBRAUSER, '-l', mFile).run
    iResult = RunCommandOn.new(mStore, 'unzip', Command::ZIMBRAUSER, '-p', mFile, iResult[1][/(JainSipApi\S+)/, 1], '|',
                               'jar', 'tv', '|', 'grep', 'IOExceptionEvent').run
    puts iResult, 'iiii'
    exitCode = iResult[0]
    if iResult[0] != 0
      exitCode = 0
      res[mStore] = ['JainsipApi1.1', 'JainSipApi1.1']
    else
      exitCode = 1
      res[mStore] = ['JainsipApi1.2', 'JainSipApi1.1']
    end
    [exitCode, res]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true 
      end
      msgs = {}
      data[1].each_pair do |k, v|
        msgs[k] = {"IS"=>"#{v[0].split("\n")[0].strip()}", "SB"=>v[1]}
      end
      mcaller.badones = {File.join(Command::ZIMBRAPATH, 'zimlets-experimental', 'com_zimbra_asterisk.zip') => msgs}
    end
  end,
=end

  v(cb("wsdl4j jar check") do 
    mObject = Action::RunCommand.new('find','root', File.join(Command::ZIMBRAPATH),"-name \"wsdl4j*.jar\"").run  
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && (data[1].nil? || data[1].include?(" ") || data[1].include?("")) 
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
