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

our $VERSION = '0.1';

get '/' => sub {
    my %modehash = (
        'S' => 'Standby',
        'P' => 'Preheat',
        'G' => 'Get Blazed!',
        'C' => 'Cooldown'
    );
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

    if ( $pw eq "butts219" ) {
        return "Bad password" unless ( $mode =~ /[CGPS]/ );
        system("echo $mode > /vape/futuremode");
        return "Mode $mode set!<br> <a href=\"/\">Home</a>";
    }
};

true;
