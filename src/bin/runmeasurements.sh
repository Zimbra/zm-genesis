#!/usr/bin/perl

use strict;

use File::Find;
use File::Basename;

#usage check
my $COMMAND_LINE="$0 @ARGV";
if ( $#ARGV != 0 )
{
	print "You typed: $COMMAND_LINE\n";
	print "Usage: $0 <SOAP output root>\n";
	print "	<SOAP output root>: the base of the *.out/*.txt files\n";
	exit 1;
}

my $SOAP_ROOT=shift (@ARGV);
my $REPORT_ROOT="$SOAP_ROOT/../MeasurementReports";
system "mkdir -p $REPORT_ROOT";

my $RAW_REPORT="$REPORT_ROOT/RawData.txt";
my $CSV_REPORT="$REPORT_ROOT/SoapMeasurements.csv";

# For Debugging
my $logFile = "$REPORT_ROOT/debug.txt";
#my $logFile = "/dev/null";
open (LOG, ">> $logFile");



my %requestTimes;




sub PROCESS_OUTFILE
{

	return unless -f $File::Find::name;

	print LOG "process ", $File::Find::name, "\n";

	if ( /.out$|.txt$/ )
	{

		# The name of the file is the name of the request
		my ($request, undef, undef) = fileparse($File::Find::name, qw/.txt .out/);

		print LOG "request ", $request, "\n";


		open FH, "<$_"
			or die "Unable to open $_: $!";

		while(<FH>)
		{
			next unless /^$request/;

			# Log this value
			print fpRAW_REPORT $_;

			chomp;


			my (undef, $total, $count, $average) = split;

			print LOG "stats $request $total $count $average\n";

			if ( !defined( $requestTimes{$request} ) )
			{
				$requestTimes{$request} = $average;
			}
			else
			{
				$requestTimes{$request} .= ",$average";
			}
		}

	}

}

sub GATHER_RESULTS
{

	open (fpRAW_REPORT, "> $RAW_REPORT")
		or die "Unable to open $RAW_REPORT: $!";

	# Parse all the .out files
	find(\&PROCESS_OUTFILE, $SOAP_ROOT);

	close (fpRAW_REPORT);

}

sub CREATE_REPORT
{

	open (fpCSV_REPORT, "> $CSV_REPORT")
		or die "Unable to open $CSV_REPORT: $!";

	while ( my($request, $timings) = each(%requestTimes) )
	{
		print fpCSV_REPORT "$request,$timings\n";
	}

	close(fpCSV_REPORT);

}

sub MAIN
{

	&GATHER_RESULTS;
	&CREATE_REPORT;
}


&MAIN;


