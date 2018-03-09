#!/usr/bin/perl
use strict;
use warnings;

use LWP::UserAgent;

BEGIN { $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0 }
my $ua = LWP::UserAgent->new;
my $server_address = "https://graphiteserver.example.com/graphite/data/shim";
#my $server_address = "http://nagios-test.example.com/cgi-bin/post_cgi.pl";

##Test Variables##
#my $AW1HostName = "Apache.Web1";
#my $AW1TimeStamp = "1234";
#my $AW1MetricValue = "1"; 
#my $AW4HostName = "Apache.Web4";
#my $AW4TimeStamp = "123456";
#my $AW4MetricValue = "2";
#my $json_string = '{ "servers": [ {"timeStamp": "$AW1TimeStamp", "hostName": "$AW1HostName", "metricValue": "$AW1MetricValue"}, {"timeStamp": "$AW4TimeStamp", "hostName": "$AW4HostName", "metricValue": "$AW4MetricValue"}]}';
#json_string prints literal variable names rather than values.

#my %json_data;

#my @servers = 

####################


my $request = HTTP::Request->new( POST => $server_address);

#add data
#my $post_data = {"timeStamp" => "12345" ,  "hostName" => "myServer.example.com", "metricValue" =>  "1" , "metricName"=> "web1"};

# my $post_data = {"data"=> "timeStamp=12345;hostName=myServer.example.com;metricValue=1;metricName=web1"};
#my $post_data = {"data"=> "testing.web1\t1\t1409751410\ntesting.web1\t1\t1409751457\ntesting.web1\t1\t1409751473\n"};

my $post_data = {"data"=> "also.is.a.test.prod.SSB1.Sample.Data\t100\t12345\nEngineering_Services.Password_Reset.DB\t100\t12345\nAuthServices.CAS.CAS1.SampleData\t100\t12345\n"};

#json attempt

#my $post_data = { "json" => $json_string };
#my $post_data = { "json" => '{ "timeStamp": "12345", "hostName":"myServer.example.com" }' };




$request->header('content-type' => 'application/json');

my $response = $ua->post( $server_address, $post_data );

#$request->content($post_data);
#my $request = $ua->request($server_address, Content => [ timestamp => "123456", metricValue => "1" , metricName => "web1" ] );

#my $response = $ua->request($request);

if($response->is_success){
        my $message = $response->decoded_content();
        print "Reply : $message\n";
}
else{
        print "HTTP POST Error Code: ", $response->code, "\n";
        print "HTTP POST Error Message: ", $response->message, "\n";
}

