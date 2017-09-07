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

my $expectedVer = '"1.6.0"';
$expectedVer = '"1.6.*"' if $options{'OS'} =~ /MACOSX/;
my $re = qr/$expectedVer/;
my $exitCode = 0;
my @res = `su - zimbra -c "zmjava -version 2>&1"`;
if (($?>>8) != 0) {
    print("error retrieving java version, exit code ".($? >> 8)."\n");
    $exitCode++;
}
else {
    my $javaVer;
    foreach my $line (@res) {
	chomp $line;
	if ($line =~ /^java version/) {
	    $javaVer = (split(/ /, $line))[2];
	    last;
	}
    }
    my $msg = "java version IS:$javaVer SB:$expectedVer\n";
    if($javaVer !~ /$re/) {
        $exitCode++;
	$msg = "error ".$msg;
    }
    print("$msg");

}
print("End ".basename($0)."\n");
exit($exitCode);


