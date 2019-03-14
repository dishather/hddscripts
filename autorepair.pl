#!/usr/bin/perl -w

# Run under root account.

use strict;

my $disk = '/dev/sdc1'; # the disk or partition to repair
my $sec = 1; # last failed sector

while( $sec != 0 )
{
    $sec = check_and_repair( $sec );
}


sub check_and_repair {
    my( $sec ) = @_;

    print "dd $sec...\n";
    my $skipsec = int( $sec / 8 ); # for disks with 4Kb sectors
    # Fast but more secure wipe: fill disk with random data.
    # openssl enc -aes-256-ctr -pass pass:"$(dd if=/dev/urandom bs=128 count=1 2>/dev/null | base64)" -nosalt < /dev/zero | dd of=/dev/sdc1 bs=4K
    # my $txt = `dd if=/dev/zero of=$disk bs=4K skip=$sec 2>&1`;
    my $txt = `dd if=$disk of=/dev/null bs=4K skip=$sec 2>&1`;
    my $RC = $?;
    print "RC=$RC\n";

    if( $RC )
    {
        dump_txt( $txt );
        $txt = `dmesg|tail -n 1`;
        dump_txt( $txt );
        if( $txt =~/ sector (\d+)/ )
        {
            print "dmesg $sec...\n";
            $sec = $1;
        }
        else
        {
            print "Sector not found, bailing out.\n";
            return 0;
        }
        print "./repair_disk.pl $sec...\n";
        $txt = `./repair_disk.pl $sec`;
        dump_txt( $txt );
        return $sec;
    }
    return 0;
}

sub dump_txt {
    my( $msg ) = @_;

    open HO, ">>autorepair.log" or die $!;
    print HO "$msg\n";
    close HO;
}
