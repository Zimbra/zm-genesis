#!/usr/bin/perl

use strict;

use File::Copy;
use File::Find;
use WWW::Mechanize;


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
#my $logFile = "$QA_EMAILS/reports.log";
my $logFile = "/dev/null";
open(LOG, ">> $logFile");

# Date and times
#
my (undef,undef,undef,$mday,$mon,$year,undef,undef,undef) = localtime;
$mon=$mon+1;
$year=$year+1900;
my $today = "$mon-$mday-$year";

# Temp files and databases
#
my $dbRoot="/opt/qa/testlogs/BugReports";
my $bugStatusDBM = "$dbRoot/bugStatus.DBM";
my $bugTestcaseDBM = "$dbRoot/bugTestcase.DBM";
my $bugQaContactDBM = "$dbRoot/bugQaContact.DBM";









my %bugsStatus;
my %bugsTestcase;
my %bugsQaContact;

my %newBugs;
my %failBugs;
my %failBugsNoAction;
my %passBugs;
my %passBugsNoAction;




sub BUGZILLA_OPEN
{
        my ($id) = (@_);
        return (
                $bugsStatus{$id} eq 'UNCONFIRMED' ||
                $bugsStatus{$id} eq 'NEW' ||
                $bugsStatus{$id} eq 'ASSIGNED' ||
                $bugsStatus{$id} eq 'REOPENED'
        );
}


sub BUGZILLA_FIXED
{
        my ($id) = (@_);
        return (
                $bugsStatus{$id} eq 'RESOLVED'
        );
}

sub BUGZILLA_CLOSED
{
        my ($id) = (@_);
        return (
                $bugsStatus{$id} eq 'VERIFIED' ||
                $bugsStatus{$id} eq 'CLOSED'
        );
}





sub STATUS_UPDATE
{
	my($tcId, $tcStatus) = (@_);

	print "STATUS_UPDATE: $tcId $tcStatus\n";

	if ( $tcStatus eq 'PASS' ) {

		# If no bugs are associated, then keep going
		if ( !defined($bugsTestcase{$tcId}) ) {
			return;
		}

		# If any open bugs are passing, list them in the report
		foreach my $bugId (split / /, $bugsTestcase{$tcId}) {
			if ( BUGZILLA_OPEN($bugId) || BUGZILLA_FIXED($bugId) ) {
				$passBugs{$bugId} = $tcId;
			} else {
				$passBugsNoAction{$bugId} = $tcId;
			}
				
		}

	} else {

		if ( !defined($bugsTestcase{$tcId}) ) {
			$newBugs{$tcId} = "NEW";
			return;
		}

		my @open;
		my @closed;
		foreach my $bugId (split / /, $bugsTestcase{$tcId}) {

			# If there are any open bugs, assume those
			# open bugs supercede any closed bugs.
			# List only the open bug(s), not the closed bugs
			#
			# If all bugs are closed, then list all of them
			# to be reopened
			#
			if ( BUGZILLA_OPEN($bugId) ) {
				push @open, $bugId;
			}
			if ( BUGZILLA_FIXED($bugId) || BUGZILLA_CLOSED($bugId) ) {
				push @closed, $bugId;
			}

		}

		if ( (@closed > 0) && (@open == 0) ) {
			foreach my $bugId (@closed) {
				$failBugs{$bugId} = $tcId;
			}
		} elsif (@open > 0) {
			foreach my $bugId (@open) {
				$failBugsNoAction{$bugId} = $tcId;
			}
		}
		
	}

}




sub PROCESS_OUT_FILE
{

	
	return unless -f $File::Find::name;
	print LOG "process ", $File::Find::name, "\n";
	
	#Files now end in .out and .txt
	if ( /.out$|.txt$/ )
	{

		open FH, "<$_"
			or warn "Unable to open $_: $!";
			
		my %testStatus;

		while(<FH>) {

			# FAIL 0326 0/1 10ms TestID TestCaseID (Broken Bug: #10145) 
			#

			next unless /^PASS|^FAIL/;

			chomp;

			my ($tcStatus, undef, undef, undef, undef, $tcId) = split /\s+/, $_;

            # Some tests use "FAIL is ok".  Mark these as pass for now
            if ( /FAIL is ok/ ) {
                    $tcStatus = "PASS";
            }

			if ( !defined( $testStatus{$tcId} ) ) {
				$testStatus{$tcId} = $tcStatus;
				print LOG "$tcId: $tcStatus\n";
			} else {
				if ( $tcStatus ne 'PASS' ) {
					$testStatus{$tcId} = $tcStatus;
					print LOG "$tcId: $tcStatus\n";
				}
			}

		}

		close FH;


		
		while ( my ($tcId, $tcStatus) = each(%testStatus) ) {
			&STATUS_UPDATE($tcId, $tcStatus);
		}



	}

}


sub GATHER_RESULTS
{

	# List all the 1) new bugs 2) open bugs 3) fixed bugs


	#Parse all the .out files for Bug_Report:

	find(\&PROCESS_OUT_FILE, $SOAP_ROOT);


}


sub CREATE_RESULTS_EMAIL_TEXT
{

	my $timeStamp = localtime;
	my $text = "\n\nAutomated bug report\n";

	
	$text .= "\n\n";
	$text .= "Date: $timeStamp\n";

	$text .= "\nBug Reports:\n";
	$text .= "(Items with an asterisk are out of sync and need follow up)\n";

	$text .= "\nFAILED TEST CASES:\n";
	while ( my ($tcId, undef) = each %newBugs )
	{
		$text .= "* NEW $tcId -- http://bugzilla.zimbra.com/enter_bug.cgi\n";
	}

	while ( my ($bugId, $tcId) = each %failBugs )
	{
		$text .= "* $bugId $bugsStatus{$bugId} $tcId ";
		$text .= " http://bugzilla.zimbra.com/show_bug.cgi?id=$bugId";
		$text .= " ( $bugsQaContact{$bugId} )\n";
	}

	while ( my ($bugId, $tcId) = each %failBugsNoAction )
	{
		$text .= "$bugId $bugsStatus{$bugId} $tcId ";
		$text .= " http://bugzilla.zimbra.com/show_bug.cgi?id=$bugId";
		$text .= " ( $bugsQaContact{$bugId} )\n";
	}

	$text .= "\nPASSED TEST CASES:\n";
	while ( my ($bugId, $tcId) = each %passBugs )
	{
		$text .= "* $bugId $bugsStatus{$bugId} $tcId ";
		$text .= " http://bugzilla.zimbra.com/show_bug.cgi?id=$bugId";
		$text .= " ( $bugsQaContact{$bugId} )\n";
	}
	while ( my ($bugId, $tcId) = each %passBugsNoAction )
	{
		$text .= "$bugId $bugsStatus{$bugId} $tcId ";
		$text .= " http://bugzilla.zimbra.com/show_bug.cgi?id=$bugId";
		$text .= " ( $bugsQaContact{$bugId} )\n";
	}

	$text;
}

sub CREATE_TEXT_FILE
{

	
	#Combine them into an e-mail format
	print "building text report ...\n";
	open FH, "> $bugsTextFile";

	#Create the plain text version
	print FH &CREATE_RESULTS_EMAIL_TEXT;


	close FH;

}


sub MAIN
{


	# Copy the DB file locally
	my $localBugStatusDBM = "/tmp/bugStatus.DBM";
	my $localBugTestcaseDBM = "/tmp/bugTestcase.DBM";
	my $localBugQaContactDBM = "/tmp/bugQaContact.DBM";
	copy("$bugStatusDBM.pag", "$localBugStatusDBM.pag")
		or die "Unable to copy $localBugStatusDBM.pag";
	copy("$bugStatusDBM.dir", "$localBugStatusDBM.dir")
		or die "Unable to copy $localBugStatusDBM.dir";
	copy("$bugTestcaseDBM.pag", "$localBugTestcaseDBM.pag")
		or die "Unable to copy $localBugTestcaseDBM.pag";
	copy("$bugTestcaseDBM.dir", "$localBugTestcaseDBM.dir")
		or die "Unable to copy $localBugTestcaseDBM.dir";
	copy("$bugQaContactDBM.pag", "$localBugQaContactDBM.pag")
		or die "Unable to copy $localBugQaContactDBM.pag";
	copy("$bugQaContactDBM.dir", "$localBugQaContactDBM.dir")
		or die "Unable to copy $localBugQaContactDBM.dir";

	# Open the DB files
	dbmopen( %bugsStatus, $localBugStatusDBM, 0644);
	dbmopen( %bugsTestcase, $localBugTestcaseDBM, 0644);
	dbmopen( %bugsQaContact, $localBugQaContactDBM, 0644);

	&GATHER_RESULTS;

	&CREATE_TEXT_FILE;

	dbmclose(%bugsStatus);
	dbmclose(%bugsTestcase);
	dbmclose(%bugsQaContact);

}




&MAIN;


