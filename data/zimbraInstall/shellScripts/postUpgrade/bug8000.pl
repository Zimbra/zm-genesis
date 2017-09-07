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

my $confDir = "/opt/zimbra/conf/";
my @files = ('perdition.pem', 'perdition.key');
my $pemHead = "-----BEGIN CERTIFICATE-----";
my $pemTail = "-----END CERTIFICATE-----";
my $keyHead = "-----BEGIN RSA PRIVATE KEY-----";
my $keyTail = "-----END RSA PRIVATE KEY-----";

my $undefined = 0;
my $exitCode = 0;

my $timestamp = (split('_', $options{'baseBuild'}))[3];
$timestamp =~ /\d\d\d\d(\d\d\d\d).*/;
if ($1 < 609) {
    print("End ".basename($0)."\n");
    exit 0;
}
foreach my $file (@files) {
    my $fn = "$confDir$file";
    next if ( -e $fn) && (-s $fn);
    print("error file $fn doesn\'t exist or empty\n");
    $exitCode++;
}
if ($exitCode == 0) {
    open FILE, "$confDir/$files[0]" or die "Couldn't open file: $!";
    my @content = <FILE>;
    close FILE;
    chomp($content[0]);
    chomp($content[$#content]);
    if (($content[0] ne $pemHead) || ($content[$#content] ne $pemTail)) {
        print("error invalid cert file $confDir/$files[0]\n");
        $exitCode++;
    }
}
if ($exitCode == 0) {
    open FILE, "$confDir/$files[1]" or die "Couldn't open file: $!";
    my @content = <FILE>;
    close FILE;
    chomp($content[0]);
    chomp($content[$#content]);
    if (($content[0] ne $keyHead) || ($content[$#content] ne $keyTail)) {
        print("error invalid cert file $confDir/$files[1]\n");
        $exitCode++;
    }
}

print("End ".basename($0)."\n");
exit($exitCode);


