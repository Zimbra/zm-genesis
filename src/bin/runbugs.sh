#!/usr/bin/perl

use strict;

use File::Find;
use File::Copy;
use WWW::Mechanize;
use XML::XPath;
use Digest::MD5;


#usage check
my $COMMAND_LINE="$0 @ARGV";
if ( $#ARGV != 0 )
{
	print "You typed: $COMMAND_LINE\n";
	print "Usage: $0 <SOAP output root>\n";
	print "	<SOAP output root>: the base of the *.out/*.txt files\n";
	exit 1;
}


#Store the command line arguments

my $SOAP_ROOT=shift (@ARGV);


my $QA_EMAILS="$SOAP_ROOT/../BugReports";
system "mkdir -p $QA_EMAILS";
my $bugsTextFile = "$QA_EMAILS/BugReport.txt";
# For Debugging
#my $logFile = "reports.txt";
my $logFile = "/dev/null";
open(LOG, "> $logFile");

# Date and times
#
my (undef,undef,undef,$mday,$mon,$year,undef,undef,undef) = localtime;
$mon=$mon+1;
$year=$year+1900;
my $today = "$mon-$mday-$year";

# Temp files and databases
#
my $dbRoot="/opt/qa/testlogs/BugReports";
system "mkdir -p $dbRoot";
my $bugStatusDBM = "$dbRoot/bugStatus$today.DBM";
my $bugTestcaseDBM = "$dbRoot/bugTestcase$today.DBM";
my $bugQaContactDBM = "$dbRoot/bugQaContact$today.DBM";







my @BUGZILLA_STATUS = qw/UNCONFIRMED NEW ASSIGNED REOPENED RESOLVED VERIFIED CLOSED/;


my %bugsStatus;
my %bugsTestcase;
my %bugsQaContact;

my %newBugs;
my %failBugs;
my %failBugsNoAction;
my %passBugs;
my %passBugsNoAction;





my %OPTS = @LWP::Protocol::http::EXTRA_SOCK_OPTS;
$OPTS{MaxLineLength} = 32768;
@LWP::Protocol::http::EXTRA_SOCK_OPTS = %OPTS;
my $mech = WWW::Mechanize->new(autocheck=>1);

sub BUGZILLA_LOGIN {

	$mech->get('http://bugzilla.zimbra.com/query.cgi?GoAheadAndLogIn=1');
	$mech->form_number(2);

	$mech->field('Bugzilla_login', 'qa-automation@zimbra.com');
	$mech->field('Bugzilla_password', 'OpJsD_JrbV');

	$mech->submit_form();

}

sub BUGZILLA_GET_BUGLIST {

	my ($query) = (@_);

	print LOG "BUGZILLA_GET_BUGLIST: $query\n";

	$mech->get($query);
	my $pageSource = $mech->content();


	my @testcaseBugs;

	# Need to parse the table
	# Example:         
	#      href="show_bug.cgi?id=32616">32616</a>
	# 
	foreach my $line (split /\n/, $pageSource)
	{
		if ( $line =~ /href=.show_bug\.cgi\?id=(\d+)/ )
		{
				print LOG "BUGZILLA_GET_BUGLIST: found $1\n";
				push(@testcaseBugs, $1);
		}
	}
	
	return (@testcaseBugs);


}

sub BUGZILLA_GET_TC_PAGE
{
	my ($id) = (@_);

	my $content = "";

	print LOG "Getting bugzilla page for $id ...\n";
	eval {
		local $SIG{ALRM} = sub {die "fetch timeout\n" };
		alarm 20;
		$mech->get ("http://bugzilla.zimbra.com/show_bug.cgi?id=$id&ctype=xml");
		alarm 0;
	};
	if($@) {
		die $@ unless ($@ eq "fetch timeout\n");
		$mech = WWW::Mechanize->new(autocheck=>1);
		&BUGZILLA_LOGIN;
	}
	else {

		$content = $mech->content;

	}

	# strip non-utf8 chars
	$content =~ s/\P{IsASCII}/?/g;

	return ($content);
}


sub BUGZILLA_GET_TC_LIST
{
	my ($id, $content) = (@_);

	my %testcaseHash = ();

	print LOG "Getting bugzilla testcases for $id ...\n";

	# Catch any invalid XML
	eval
	{
		my $xp = XML::XPath->new($content);
		foreach my $node ($xp->find('//testcase')->get_nodelist)
		{
			$testcaseHash { $node->string_value } = 1;
		}
	};
	if ($@)
	{
		$testcaseHash { "InvalidXML" } = 1;
	}

	return (keys %testcaseHash);

}

sub BUGZILLA_GET_QA_CONTACT
{
	my ($id, $content) = (@_);

	my $contact = "None";

	print LOG "Getting bugzilla QA Contact for $id ...\n";

	# Catch any invalid XML
	eval
	{
		my $xp = XML::XPath->new($content);
		foreach my $node ($xp->find('//qa_contact')->get_nodelist)
		{
			$contact = $node->string_value;
		}
	};
	if ($@)
	{
		$contact = "InvalidXML";
	}

	return ($contact);

}


sub UniqueArray
{
	my ($new, @list) = (@_);

	foreach (@list) {
		return (@list)          if /$new/;
	}

	push @list, $new;
	return (@list);
}




sub GATHER_BUG_STATUS
{
	# Search for all bugs, by status, with at least one
	# testcase_id associated
	#
	foreach my $status ( @BUGZILLA_STATUS )
	{

		my @bugList = &BUGZILLA_GET_BUGLIST( "http://bugzilla.zimbra.com/buglist.cgi?field0-0-0=testcase_count&type0-0-0=greaterthan&value0-0-0=0&bug_status=$status" );

		# For each bug ID, get a list of associated test cases
		#
		foreach my $bugId (@bugList)
		{

			$bugsStatus{$bugId} = $status;

		}

	}

}

sub GATHER_BUG_DATA
{

	# For each bug ID, get a list of associated test cases
	#
	foreach my $bugId (sort keys %bugsStatus) {

		my $content = &BUGZILLA_GET_TC_PAGE($bugId);

		my @testcaseList = &BUGZILLA_GET_TC_LIST($bugId, $content);

		foreach my $testcaseId (@testcaseList) {

			if ( !defined($bugsTestcase{$testcaseId}) ) {
				# Init the hash
				$bugsTestcase{$testcaseId} = "";
			}
			my @bugs = &UniqueArray($bugId, split / /, $bugsTestcase{$testcaseId});

			$bugsTestcase{$testcaseId} = "@bugs";

			print LOG "$testcaseId: $bugsTestcase{$testcaseId}\n";

		}

		my $contact = &BUGZILLA_GET_QA_CONTACT($bugId, $content);
		$bugsQaContact{$bugId} = $contact;


	}

}

sub WRITE_MD5_FILE
{
	my ($filename) = (@_);

	open(FILE, "<$filename") or die "Can't open md5: $!";
	my $md5=Digest::MD5->new;
	while(<FILE>) {
	        $md5->add($_);
	}
	close(FILE);
	
	open (OUT, ">${filename}.MD5");
	print OUT $md5->b64digest, "\n";
	close(OUT);

}

sub WRITE_TXT_TO_MD5
{
	&WRITE_MD5_FILE("$dbRoot/bugStatus.txt");
	&WRITE_MD5_FILE("$dbRoot/bugTestcase.txt");
	&WRITE_MD5_FILE("$dbRoot/bugQaContact.txt");
}

sub WRITE_DB_TO_TXT
{

	open(BUGSTATUS, "> $dbRoot/bugStatus.txt");
	open(TESTCASE, "> $dbRoot/bugTestcase.txt");
	open(CONTACT, "> $dbRoot/bugQaContact.txt");
	
	while ( my ($bug, $status) = each(%bugsStatus) )
	{
		print BUGSTATUS "$bug	$status\n";
	}

	while ( my ($tc, $bugs) = each(%bugsTestcase) )
	{
		print TESTCASE "$tc	$bugs\n";
	}
	while ( my ($bug, $contact) = each(%bugsQaContact) )
	{
		print CONTACT "$bug	$contact\n";
	}

	close(BUGSTATUS);
	close(TESTCASE);
	close(CONTACT);

}

sub GATHER_BUGS
{

	# Open the databases
	#
	dbmopen( %bugsStatus, $bugStatusDBM, 0644);
	dbmopen( %bugsTestcase, $bugTestcaseDBM, 0644);
	dbmopen( %bugsQaContact, $bugQaContactDBM, 0644);

	# Login to bugzilla
	&BUGZILLA_LOGIN;

	# Get the status of all bugs with testcases (%bugsStatus)
	&GATHER_BUG_STATUS;

	# Get the testcases of all bugs with testcases (%bugsTestcase)
	&GATHER_BUG_DATA;

	# For windows, write the data to a text file
	&WRITE_DB_TO_TXT;
	&WRITE_TXT_TO_MD5;

	dbmclose(%bugsStatus);
	dbmclose(%bugsTestcase);
	dbmclose(%bugsQaContact);

}







sub MAIN
{

	&GATHER_BUGS;

	# Move the temp database files to the 'live' file names
	move("$bugStatusDBM.pag", "$dbRoot/bugStatus.DBM.pag");
	move("$bugStatusDBM.dir", "$dbRoot/bugStatus.DBM.dir");
	move("$bugTestcaseDBM.pag", "$dbRoot/bugTestcase.DBM.pag");
	move("$bugTestcaseDBM.dir", "$dbRoot/bugTestcase.DBM.dir");
	move("$bugQaContactDBM.pag", "$dbRoot/bugQaContact.DBM.pag");
	move("$bugQaContactDBM.dir", "$dbRoot/bugQaContact.DBM.dir");

}




&MAIN;



