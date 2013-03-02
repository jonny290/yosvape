use Irssi;

our $VERSION = '1.05';
our %IRSSI = (
    authors     => 'Jonny 290',
    contact     => 'jonny290@gmail.com',
    name        => 'YOSVape Alert',
    description => 'Alerts IRC to vaporizer '
                  .  'Status changes',
    license     => 'Death License 2000',
);


my $lastmode;
my $temp;
my $pwm;
my $setpoint;
my $timestamp;
my $lastmodechg;
my $msg;
my $preheated = 0;
my %modes = ("S" => "Standby","P" => "Preheat", "G" => "GET BLAZED!!!", "C" => "Cooldown");
my $statusline = `tail -1 /vape/yosvape.log 2> /dev/null`;

return unless $statusline;
($timestamp,$currmode,$pwm,$temp,$setpoint) = split(/,/,$statusline);

Irssi::signal_add 'message public', 'vape_message_public';

sub vape_message_public {
    my ($server, $msg, $nick, $nick_addr, $target) = @_;
    return unless ($target =~ m/#yospos/);  # only operate in these channels

    if ($nick eq "jonny290" && $msg =~ /^!preheat/) {
        system('echo P > /vape/futuremode');
        $server->command("msg $target Please wait, \cC5$nick\cO. \cC5YOSVape\cO is preheating." ) ;
    } elsif ($msg =~ m/^!status/i) {
        &vapestatus;
    }    
}



sub vapecheck {
    my $currmode;
    my $statusline = `tail -1 /vape/yosvape.log 2> /dev/null`;

    return unless $statusline;
    ($timestamp,$currmode,$pwm,$temp,$setpoint) = split(/,/,$statusline);

    if ($currmode ne $lastmode) {
        $lastmode = $currmode;
        my $modetime = ($timestamp - $lastmodechg) ;
        $msg = "\cC5[\cC3YOSVAPE\cC5] \cC2$modes{$currmode} \cO| current temp: \cC2 $temp F \cO| setpoint:\cC4 $setpoint F \cO| last phase duration\cC3 $modetime \cOseconds";
        $lastmodechg = $timestamp;
    }

    $preheated = 0 if ($currmode ne "P");

    my $c = Irssi::server_find_chatnet("syn")->channel_find("#yospos");
        Irssi::print("$currmode, $temp, $pwm, $preheated", MSGLEVEL_CLIENTCRAP);

    if (($currmode eq "P") && (int($temp) > 319) && (int($pwm) < 195) && ($preheated == 0)) {
        my $modetime = ($timestamp - $lastmodechg) ;
        $c->command("msg #yospos \cC5YOSVAPE \cOis preheated. Temperature:\cC2 $temp F\cO, preheat time\cC3 $modetime \cOseconds."); 
        $preheated = 1;
    } 

    if  ($msg) {
        $c->command("msg #yospos $msg");
        undef $msg;
    }
}


sub vapestatus {
    my $currmode;
    my $statusline = `tail -1 /vape/yosvape.log 2> /dev/null`;

    return unless $statusline;
    ($timestamp,$currmode,$pwm,$temp,$setpoint) = split(/,/,$statusline);

    my $modetime = ($timestamp - $lastmodechg) ;
    $msg = "\cC5[\cC3YOSVAPE\cC5] \cC2$modes{$currmode} \cO| current temp: \cC2 $temp F \cO| setpoint:\cC4 $setpoint F \cO| last phase duration\cC3 $modetime \cOseconds";
    $lastmodechg = $timestamp;

    my $c = Irssi::server_find_chatnet("syn")->channel_find("#yospos");

    if  ($msg) {
        $c->command("msg #yospos $msg");
        undef $msg;
    }
}

Irssi::timeout_add(10000,'vapecheck',undef);

"Smoke weed everyday - Snoop Dogg";
