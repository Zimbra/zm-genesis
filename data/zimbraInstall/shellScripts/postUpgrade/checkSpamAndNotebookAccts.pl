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

my %expectedAccounts = ();
my @allConfigAccts = ('zimbraSpamIsSpamAccount',
                      'zimbraSpamIsNotSpamAccount',
                      'zimbraNotebookAccount');
foreach my $config (@allConfigAccts) {
    my $cfg = `su - zimbra -c "zmprov gcf $config"`;
    chomp $cfg;
    my $acct = (split(/ /, $cfg))[1];
    $expectedAccounts{$acct} = 1;
}

my $exitCode = 0;

foreach my $acct (`su - zimbra -c "zmprov gaa"`) {
    chomp $acct;
    my $res = `su - zimbra -c "zmprov ga $acct" | grep zimbraIsSystemResource`;
    if (grep(/zimbraIsSystemResource: TRUE/, $res) != 0) {
        if (!exists $expectedAccounts{$acct}) {
            my $expected = "None";
            foreach my $key (keys %expectedAccounts) {
                if (lc($key) eq lc($acct)) {
                    $expected = $key;
                    last;
                }
            }
            $exitCode++;
            print("error Spam/Notebook account mismatch IS:$expected SB:$acct\n");
        }
    }
}
if($exitCode) {
    print("found $exitCode errors\n");
}

print("End ".basename($0)."\n");
exit($exitCode);


