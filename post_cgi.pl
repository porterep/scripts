#!/usr/bin/perl
use strict;
use warnings;
use IO::Socket::INET;
#use JSON qw( decode_json );
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);
my $c = new CGI;
print $c->header('application/json');
#print $c->request_method;

my $graphite_socket_string;


if($c->request_method eq "POST")
#{

#json
#my $json_data = decode_json(param('json')) or die "Not JSON";

#Works

#my $timeStamp = param('timeStamp') || '<i>(No input)</i>';
#my $hostName = param('hostName') || '<i>(No input)</i>';
#my $metricName = param('metricName') || '<i>(No input)</i>';
#my $metricValue = param('metricValue') || '<i>(No input)</i>';


#string to send to graphite
my $graphite_string;
my $hostName;
my $metricValue;
my $metricName;
my $timeStamp;
my $data = param('data');
#print $data;
my @lines = split /\n/, $data;
foreach my $line(@lines) {
#(timeStamp, $hostName, $metricValue, $metricName) = split /\t/, $line;
($metricName, $metricValue, $timeStamp, $hostName) = split /\t/, $line;
$graphite_string .= $metricName ." ". $metricValue ." ". $timeStamp . "\n";
}
send_data($graphite_string);
#print $graphite_string;
#print $graphite_string;
#my @Servers = @{$json_data->{'servers'}};
#foreach my $s (@Servers) {
#       print $s->{'timeStamp'} . " " . $s->{'hostName'} . " " . $s->{'metricValue'} . " " . "\n";
}


#print <<END;
#Content-Type: text/html; charset=iso-8859-1
#
#<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
#<title>Echoing user input</title>
#<h1>Echoing user input</h1>
#<p>You submitted: </p>
#<p>timeStamp : $timeStamp</p>
#<p>hostName : $hostName</p>
#<p>metricName : $metricName</p>
#<p>metricValue : $metricValue</p>
#END

#       print "Success";
#}
#else
#{
#       print "Error";
#}
#print "Hello, World.";
print "data received";
0;

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

