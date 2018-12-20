#!/usr/bin/perl
use strict;
use warnings;
use IO::Socket::INET;
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);
my $c = new CGI;
print $c->header('application/json');

my $graphite_socket_string;

if($c->request_method eq "POST")

#string to send to graphite
my $graphite_string;
my $hostName;
my $metricValue;
my $metricName;
my $timeStamp;
my $data = param('data');
my @lines = split /\n/, $data;
foreach my $line(@lines) {
($metricName, $metricValue, $timeStamp, $hostName) = split /\t/, $line;
$graphite_string .= $metricName ." ". $metricValue ." ". $timeStamp . "\n";
}
send_data($graphite_string);

#subroutines
sub send_data
{
        my ($data) = @_;
        my $carbon_address = '172.27.18.37';
        my $carbon_port = '2003';
        my $protocol = 'tcp';
        my $socket = new IO::Socket::INET(PeerAddr => $carbon_address, PeerPort => $carbon_port, Proto => $protocol);
        $socket or die "No socket: $!";
        $socket->send($data);
        close($socket);
}

