#!/usr/bin/perl -w

use strict;

$|=1;

# failed s: 395316440
my $first = 0;
my $last  = 2930277167;
my $dev   = '/dev/sdc'; # cannot be a partition!

if( scalar( @ARGV ) )
{
    my $sec = 0 + shift @ARGV;
    $first = int( $sec / 1000 ) * 1000;
    $last = int( $sec / 1000 + 2 ) * 1000;
    if( scalar( @ARGV ) )
    {
        $last = 0 + shift @ARGV;
        $last = int( $last / 1000 ) * 1000;
    }
}

my $failed = 0;
my $r;

for( my $i = $first; $i < $last; ++$i )
{
    if( ( $i % 10000 ) == 0 )
    {
        print "\nFailed sectors: $failed";
        open HO, ">repair_disk.status" or die $!;
        print HO "sector: $i\nfailed: $failed";
        close HO;
    }
    print "\n$i" if( ( $i % 100 ) == 0 );
    $r = exec_read( $i );
    print $r;
    if( $r ne '.' )
    {
        ++$failed;
        $r = exec_write( $i );
        print "\b$r";
        if( $r eq 'W' )
        {
            $r = exec_read( $i );
            $r = '*' if( $r eq '.' );
            print "\b$r";
        }
        # last if $r ne '*';
    }
}
print "\nFailed sectors: $failed\n";

sub exec_read {
    my( $i ) = @_;

    my $r = `hdparm --read-sector $i $dev 2>&1`;
    if( $? )
    {
        return '!';
    }
    return '.';
}

sub exec_write {
    my( $i ) = @_;

    my $r = `hdparm --repair-sector $i --yes-i-know-what-i-am-doing $dev 2>&1`;
    if( $? )
    {
        # possibly hardware error and the disk got disconnected. Give it
        # some time to reappear.
        sleep 20;
        return 'X';
    }
    return 'W';
}
