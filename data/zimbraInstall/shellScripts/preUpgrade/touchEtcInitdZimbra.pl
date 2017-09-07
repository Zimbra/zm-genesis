#!/usr/bin/perl

use strict;

use Getopt::Long;
use File::Basename;

our %options = ();
my @allNames = ('bits', 'machine', 'OS', 'build', 'branch',
                'baseBuild', 'targetBuild');

$| = 1;

## strictCheck = 1 check for values in expected config
##             = 0 check whether isConfig{key} exists
my $strictCheck = 1;

print("Start ".basename($0)."...\n");
GetOptions (\%options, 'bits=s', 'machine=s', 'OS=s', 'build=s',
                       'branch=s', 'baseBuild=s', 'targetBuild=s');

#foreach my $opt (keys %options) {
#   print "options{$opt}=$options{$opt}\n";
#}

my $zimbraFile = "/etc/init.d/zimbra";

my $exitCode = 0;
if ($options{'OS'} !~ /MACOSX/i) {
    if (open (FILE, ">>$zimbraFile") != 0) {
	seek(FILE,0,2);
	print(FILE "#blah blah");
	close(FILE);
    }
    else {
	print("error: Couldn't open $zimbraFile - $!\n");
	$exitCode++;
    }
}
else {
    print("$options{'OS'} build, skipping...\n");
}

print("End ".basename($0)."\n");
exit($exitCode);


