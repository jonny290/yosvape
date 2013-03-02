#This is a Dancer module to provide a rudimentary webUI to YOSVape.
#Any Dancer template or code contributions will likely be taken;
#please make them as hilarious as possible.
#
#-290
################################
# HISTORY #
###########
#
# 3/1/2013 0.420 initial release

package yosvape;
use Dancer ':syntax';
use DateTime;
use File::Slurp;
use Config::General;

our $VERSION = '4.20';

our $conf_obj   = Config::General->new( 'yosvape.conf' );
our %conf_all   = $conf_obj->getall;     # Access all configuration
our %conf       = %{$conf_all{vapelog}}; # Access vapelog specific configuration

our %modehash = (
    'S' => 'Standby',
    'P' => 'Preheat',
    'G' => 'Get Blazed!',
    'C' => 'Cooldown'
);


get '/' => sub {
    my @logcat  = `tail -1 /vape/yosvape.log 2> /dev/null`;
    my $logline = $logcat[0];
    chomp($logline);
    my @line = split( ',', $logline );
    my $return =
        "<center><h2>YOSVAPE STATUS</h2>"
      . "<br /><br />"
      . "<h4>Mode:</h4> $modehash{$line[1]} <br />"
      . "<h4>Temp:</h4> $line[3] <br />"
};

get '/*/*' => sub {
    my ( $pw, $mode ) = splat;
    return "bad password" unless ($pw eq "butts219");

    if( defined($modehash{$mode}) ) {
        system("echo $mode > /vape/futuremode");
        return "Mode $mode set!<br> <a href=\"/\">Home</a>";
    }
    else {
        return "mode:[$mode] not valid";
    }

    return 69 . ' LOL'; 
};

get '/guilty' => sub {
    # provide the fbi with general drug usage logs
    return read_file($conf{usagelog});
};

true;