#!/usr/bin/perl -w

use Cwd;
use Cwd 'abs_path';
use File::Find;
use File::Copy;
use File::Basename;
use XML::Simple;
use Data::Dumper;


# Determine the //depot/ZimbraQA path
# (Assume runmapi.pl runs in data/mapiValidator)
#
my $ZIMBRAQA_ROOT = dirname($0);
$ZIMBRAQA_ROOT = abs_path("$ZIMBRAQA_ROOT/../..") . "/";



# Set the perl command
# Add //depot/ZimbraQA to the include path
#
my $perl_com = "perl -I $ZIMBRAQA_ROOT";


# Set the ZMROOT path ... currently not needed for anything
#
my $ZMROOT="/opt/zimbra";


# Where is Java?
# Use the Zimbra Java, if available
#
my $JAVA_COM="java";
if ( -x "$ZMROOT/java/bin/java" ) {
	$JAVA_COM="$ZMROOT/java/bin/java"
}



my $log4j_conf_file="$ZIMBRAQA_ROOT/conf/log4j.properties";
my $global_conf_file="$ZIMBRAQA_ROOT/conf/global.properties";

# TODO: How to differentiate running between windows, linux, etc.
# For now, since Win32::OLE is only available on windows, hard code to windows classpath style
my $zimbra_class_path = "$ZIMBRAQA_ROOT/build/dist/zimbra-0.5.0/lib/zimbraqa.jar;$ZMROOT/lib/zimbrastore.jar;$ZMROOT/lib/commons-cli-2.0.jar;$ZMROOT/lib/dom4j-1.5.jar;$ZMROOT/lib/log4j-1.2.8.jar;$ZMROOT/lib/commons-httpclient-2.0.1.jar;$ZMROOT/lib/commons-logging.jar;$ZMROOT/lib/jaxen-1.1-beta-3.jar;$ZMROOT/lib/ical4j-0.9.16-patched.jar;$ZMROOT/lib/javamail-1.4.3.jar;$ZMROOT/lib/activation.jar";

my $java_args = "-cp $zimbra_class_path com.zimbra.qa.soap.SoapTestCore -l $log4j_conf_file -d -p $global_conf_file";



# Parse any arguments
my (@testCaseList) = @ARGV;
print "Run test cases: @testCaseList\n";


my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime time;
$year += 1900;
my $tag = sprintf "%04d%02d%02d%02d%02d%02d", $year, $mon, $mday, $hour, $min, $sec;

#Create a log directory if not already present
my $logDir = $ZIMBRAQA_ROOT . "data/mapiValidator/log/";
mkdir($logDir, 0755) || warn "Cannot mkdir $logDir; maybe it already exists: $!";

#Create a log file to maintain results.
my $logFile = "results-$tag.txt";
my $logFilePath = $logDir.$logFile;

#TODO: To set any global property, it must be WRITABLE
&setGlobalProperty("logfilepath",$logFilePath);

#
#Header of the log file
&writeLogFile("Results\n---------------\n");



sub shouldSkip {

	my ($testcase) = @_;
	
	# returns 1 if the test should be skipped
	# returns 0 if the test should be executed
	#
	my $skipIt = 1;
	my $executeIt = 0;


	if ( @testCaseList ) {
		

		# If a specific test case is desired, but the testcase.xml does
		# not define the testcaseid, then skip it
		#
		
		if ( ! defined ($testcase->{testcaseid}) ) {
			return $skipIt;	# No matches
		}
		
		# Look at each test case in the argument list,
		# if a match is found, then we shouldn't skip this test
		#
		
		foreach my $i (@testCaseList) {
			
			if ( $testcase->{testcaseid} eq $i ) {
				return $executeIt;
			}
			
		}
		
		# We went through the list and didn't find a match.  Skip this test!
		#
		
		return $skipIt;	# No matches
		
	}

	# default should be execute?
	#
	
	return $executeIt;
	
}

sub writeLogFile {

	my ($text) = @_;
	
	print "$text\n";
	
	open(FILE,">>$logFilePath");
	print FILE "$text\n";
	close(FILE);

}

sub writeTestResult {

	&writeLogFile("\t\t@_");

}


sub parseTestText {


	/testcase\.xml/ or return;

	my $xmlfile = $_;
	

	my $xml = new XML::Simple;
	my $testcase = $xml->XMLin($xmlfile, forcearray => [ 'filename' ]);

	print "<html>\n";
	print "<body>\n";
	
	print "<table border=\"1\">\n";

	print "<tr>\n";
	print "<th>Test Case ID</th>  <th>Objective</th>\n";
	print "</tr>\n";

	print "<tr>\n";
	print "<td>\n";
	print $testcase->{testcaseid};
	print "</td>\n";
	print "<td>\n";
	print $testcase->{objective} if (defined($testcase->{objective}));
	print "</td>\n";
	print "</tr>\n";
	
	print "</table>\n";
	
	
	print "</body>\n";
	print "</html>\n";
			
}


#
#setGlobalProperty has been currently duplicated in runmapi.pl and qaTest.pl
#TODO: Need to find a way to call any function defined in qaTest.pl from runmapi
#

sub setGlobalProperty 
{ 	
	my($key,$value) = @_;
	
	#Open the global properties file to read the existing data	
	open (FILE1, $global_conf_file);

	#
	#Create an intermediate temp file to write all values that wont be changed
	#as it is, and write the values to be changed after changing them
	#This temp file would be again copied back to the original file so that
	#new values are reflected in global properties file
	#Need to find a more efficient way of doing this
	#
	open (FILE2, ">$global_conf_file.tmp");
	my $flag = 0;

	while (<FILE1>) {

		my $line = $_;
		
		if (/^$key=/) {
		
			$line =~ s/^(.*)=.*$/$1=$value/;
			$flag = 1;
		}
		
		print FILE2 $line;
	
	}

	if (!$flag) {

		print FILE2 "$key=$value";
	}

	close (FILE1);
	close (FILE2);

	move ("$global_conf_file.tmp", $global_conf_file);

	return ($value);
	
}

sub executeJava {
	my ($filename, $directory) = @_;

	my $ret = system("$JAVA_COM $java_args -f $filename");
	
	return ($ret);
}
	
sub executeMapi {
	my ($filename, $directory) = @_;

	my $ret = system("$perl_com $filename");
	
	return ($ret);
}
	

sub main {

	
	
	# Traverse the directory, looking for files name testcase.xml
	my $basedir = ".";
	
	# Wish we could use XSLT, but I got tired of looking for XML::XSLT ...
	# XML::XSLT does not come standard with ActivePerl
	#
	find(\&parseTestText, $basedir);
	
	
}




#&main;


print "Content-type: text/html\n\n";
print "hello, world!\n";

