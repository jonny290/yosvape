#!/usr/bin/perl

use Device::SerialPort;

$LOGDIR  = "/vape";           # path to data file
$LOGFILE = "yosvape.log";    # file name to output to
$PORT    = "/dev/ttyACM0";    # port to watch

#
#
# Serial Settings
#
#

$ob = Device::SerialPort->new($PORT) || die "Can't Open $PORT: $!";
$ob->baudrate(9600)    || die "failed setting baudrate";
$ob->parity("none")    || die "failed setting parity";
$ob->databits(8)       || die "failed setting databits";
$ob->handshake("none") || die "failed setting handshake";
$ob->dtr_active(0)     || die "failed setting dtr_active";
$ob->write_settings    || die "no settings";

#
# open the logfile, and Port
#

open( LOG, ">>${LOGDIR}/${LOGFILE}" )
  || die "can't open smdr file $LOGDIR/$LOGFILE for append: $SUB $!\n";

#select(LOG),
$| = 1;    # set nonbufferd mode

#
# Loop forver, logging data to the log file
#

$ob->are_match("\n");
my $line;
while (1) {    # print input device to file
    $line = $ob->lookfor;
    if ($line) {
        print LOG "$line\n";
        my ( $uptime, $mode, $pwm, $temp, $setpoint ) = split( /,/, $line );
        my $currentmode = $mode;
        my $futuremode  = `cat /vape/futuremode`;
        chomp($futuremode);
        if ( $futuremode && $futuremode ne $currentmode ) {
            $ob->write($futuremode) if ( $futuremode =~ /\w/ );
            print "MODE CHANGE TO $futuremode\n";
            unlink('/vape/futuremode');
        }
    }
    select( undef, undef, undef, 0.5 );

}

undef $ob;
