package yosvape;
use Dancer ':syntax';

our $VERSION = '0.1';

#set serializer => 'JSON';

#get '/hello/:name' => sub {
    # this structure will be returned to the client as
    # {"name":"$name"}
#    return {name => params->{name}};
#};
get '/' => sub {
	my %modehash = ('S'=> 'Standby','P' => 'Preheat','G' => 'Get Blazed!','C' => 'Cooldown' );
    my @logcat =  `tail -1 /vape/yosvape.log 2> /dev/null`;
	my $logline = $logcat[0];
	chomp($logline);
	my @line = split(',',$logline);
	my $return = "<center><h2>YOSVAPE STATUS</h2>"
			. "<br /><br />"
			. "<h4>Mode:</h4> $modehash{$line[1]} <br />"
			. "<h4>Temp:</h4> $line[3] <br />"

};

get '/*/*' => sub {
	
my ($pw, $mode) = splat;

if ($pw eq "butts219") {
	return "Bad password" unless ($mode =~ /[CGPS]/);
	system("echo $mode > /vape/futuremode");
	return "Mode $mode set!<br> <a href=\"/\">Home</a>";
}
};

true;
