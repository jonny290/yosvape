#!/usr/bin/perl
#YOSVape Logger
#JONNY 290 2013
#
# Designed to be kept alive by yosvape.sh.
#

use strict;
use warnings;
use Device::SerialPort;
use Config::General;
use Getopt::Long::Descriptive;
 
our $VERSION = '0.000_420';

# Use Getopt::Long::Descriptive to override default config
my ($opt, $usage) = describe_options(
    "$0 %o <some-arg>",
    [   'config|c:s',  "load config file",            { default => 'yosvape.conf' }],
    [   'logdir|d:i',  "the directory to logfile",    { default => '/vape'        }],
    [   'logfile|f:s', "the file for yosvape to use", { default => 'yosvape.log'  }],
    [   'port|p:s',    "the port for some shit",      { default => '/dev/ttyACM0' }],
    [],
    [   'help',        "print usage message and exit" ],
);

my $conf_obj   = Config::General->new( $opt->config );
my %conf_all   = $conf_obj->getall;     # Access all configuration
my %conf       = %{$conf_all{vapelog}}; # Access vapelog specific configuration
$conf{logdir}  = $opt->logdir  || $conf{logdir };
$conf{logfile} = $opt->logfile || $conf{logfile};
$conf{port}    = $opt->port    || $conf{port   };


print($usage->text), exit if $opt->help;

my $LOGFILE = $conf{logdir} . '/' . $conf{logfile};

# Serial Settings
my $ob = Device::SerialPort->new($conf{port}) || die "Can't Open " . $conf{port} . ": $!";
$ob->baudrate(9600)    || die "failed setting baudrate";
$ob->parity("none")    || die "failed setting parity";
$ob->databits(8)       || die "failed setting databits";
$ob->handshake("none") || die "failed setting handshake";
$ob->dtr_active(0)     || die "failed setting dtr_active";
$ob->write_settings    || die "no settings";

$ob->are_match("\n"); #This sets the characters we consider a record separator, basically

open( my $logfile, '>>', $LOGFILE )  || die "can't open smdr file $LOGFILE for append: $!\n";
$| = 1;    # set nonbufferd mode

# Loop forver, logging data to the log file
while (1) {    # dont stop till u get enough
    if (my $line = $ob->lookfor) {   #Returns undef if we havent gotten an are_match - terminated string, or the string if we have
        print {$logfile} $line;
        my ( $uptime, $mode, $pwm, $temp, $setpoint ) = split( /,/, $line );

        my $futuremode  = `cat /vape/futuremode`;
        chomp($futuremode);

        if ( $futuremode && $futuremode ne $mode ) {
            $ob->write($futuremode) if ( $futuremode =~ /\w/ );
            print "MODE CHANGE TO $futuremode\n";
            unlink('/vape/futuremode');
        }
    }
    select( undef, undef, undef, 0.5 ); #ancient chinese secret for sub-1s naps without time::hires or shelling out
}
undef $ob;

"420" || 1;
