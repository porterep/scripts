#!/usr/bin/perl
use strict;
use warnings;

use LWP::UserAgent;

BEGIN { $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0 }
my $ua = LWP::UserAgent->new;
my $server_address = "https://graphiteserver.example.com/graphite/data/shim";

my $request = HTTP::Request->new( POST => $server_address);

#add data

my $post_data = {"data"=> "also.is.a.test.prod.SSB1.Sample.Data\t100\t12345\nEngineering_Services.Password_Reset.DB\t100\t12345\nAuthServices.CAS.CAS1.SampleData\t100\t12345\n"};

$request->header('content-type' => 'application/json');

my $response = $ua->post( $server_address, $post_data );

if($response->is_success){
        my $message = $response->decoded_content();
        print "Reply : $message\n";
}
else{
        print "HTTP POST Error Code: ", $response->code, "\n";
        print "HTTP POST Error Message: ", $response->message, "\n";
}

