#!/usr/bin/perl
#use strict;
#use warnings;
use IO::Socket::INET;
use Text::CSV_XS;
use DateTime::Format::Strptime;
use LWP::UserAgent;
use JSON qw(encode_json);

#DateTime,Hostname,Apache_80,Apache_80_TW,Apache_443,Apache_443_TW,Apache_10443,Apache_10443_TW,Apache_20443,Apache_20443_TW,SSB1_OHS_9075,SSB2_OHS_9075,SSB3_OHS_9075,SSB4_OHS_9075,SSB1_OHS_9075_CW,SSB2_OHS_9075_CW,SSB3_OHS_9075_CW,SSB4_OHS_9075_CW,SSB1_WLS_7003,SSB2_WLS_7003,SSB3_WLS_7003,SSB4_WLS_7003,SSB1_WLS_7003_CW,SSB2_WLS_7003_CW,SSB3_WLS_7003_CW,SSB4_WLS_7003_CW,SSB1_WLS_9203,SSB2_WLS_9203,SSB3_WLS_9203,SSB4_WLS_9203,SSB1_WLS_9203_CW,SSB2_WLS_9203_CW,SSB3_WLS_9203_CW,SSB4_WLS_9203_CW,loadAvg1,loadAvg5,loadAvg15,ReqPerSec,BusyHTTP,IdleWorkers

print STDERR "Processing datafile\n";


@TimeSeries = ();

$FileName = $ARGV[0] ;

$SourceFilePath; # = qw( logs/ );
$TargetFilePath = qw( graphs/ );



#Array for epoch time;
my @epoch_array;



#Looping through files can begin here.


#print "Source Datafile incoming [${
$FileDate; # = $FileName; $FileDate =~ s/(.*)-(.{8})-webstats.*/$2-$1/;
# ssbstats/oc-qa-web1-20130824-webstats.csv
#     logs/oc-qa-web1-20130828-webstats.csv
$FileName = $SourceFilePath . $FileName;

print "File Name [${FileName}]  File Date [${FileDate}]\n";

my @rows;

my $csv = Text::CSV_XS->new ({ binary => 1, auto_diag => 1 });
# open my $fh, "<:encoding(utf8)", ${FileName} or die "${FileName}: $!";

my @files = </var/home/naguser/data/*.csv>;

foreach my $csv_file (@files){


open my $fh, "<", ${FileName} or die "${FileName}: $!";

@Apache_80 = (), @Apache_80_TW = (), @Apache_443 = (), @Apache_443_TW = ();
@Apache_10443 = (),  @Apache_10443_TW = (), @Apache_20443 = (),  @Apache_20443_TW = ();
@SSB1_OHS_9075 = (), @SSB2_OHS_9075 = (),   @SSB3_OHS_9075 = (), @SSB4_OHS_9075 = ();
@SSB1_OHS_9075_CW = (), @SSB2_OHS_9075_CW = (), @SSB3_OHS_9075_CW = (), @SSB4_OHS_9075_CW = ();
@SSB1_WLS_7003 = (), @SSB2_WLS_7003 = (), @SSB3_WLS_7003 = (), @SSB4_WLS_7003 = ();
@SSB1_WLS_7003_CW = (), @SSB2_WLS_7003_CW = (), @SSB3_WLS_7003_CW = (), @SSB4_WLS_7003_CW = ();
@SSB1_WLS_9203 = (), @SSB2_WLS_9203 = (), @SSB3_WLS_9203 = (),@SSB4_WLS_9203 = ();
@SSB1_WLS_9203_CW = (), @SSB2_WLS_9203_CW = (), @SSB3_WLS_9203_CW = (), @SSB4_WLS_9203_CW = ();
@loadAvg1 = (), @loadAvg5 = (), @loadAvg15 = ();
@ReqPerSec = (),@BusyHTTP = (), @IdleWorkers = ();


# Get Column names and associate
my @cols = @{$csv->getline ($fh)};
$csv->column_names (@cols);

#print " Cols : " . @cols;

#  foreach my $keyb ( @cols ) {
#   print " Entry : [$keyb]\n";
#}

my $InitialDateTime ="", $FinalDateTime = "", $DataServerName="", $RowCount=0, $LogoFileName="";


 while (my $row = $csv->getline_hr ($fh)) {


#Read this fileDate [08/26/13 00:00:01]
#Read this fileDate [08/28/2013 00:00:01]

     my $fileDate = $row->{'DateTime'}?$row->{'DateTime'}: $row->{'Date-Time'}?$row->{'Date-Time'}:"00/00/0000" ;
     $fileDate =~ s/(\d{2}\/\d{2}\/)(\d{2}) /${1}20${2} /;

                                              #    Date-Time
#     print " 1 ". $row->{'DateTime'} ." 2 ". $row->{'Date-Time'}. "\n";
#     print "Read this fileDate [${fileDate}]\n";
#exit;
     if (! ( ( substr( $fileDate, 11, -3 ) gt "00:00" ) & ( substr( $fileDate, 11, -3 ) lt "24:00" )))
     { next; }
     $RowCount++;
#print " fileDate
     push(@TimeSeries,$fileDate); #substr($fileDate, 11, -3 ));

     if ( $RowCount == 1 ) {
        $InitialDateTime = $fileDate;
        $DataServerName = $row->{'Hostname'}?$row->{'Hostname'}: $row->{'HostName'}?$row->{'HostName'}: $row->{'HOSTNAME'}?$row->{'HOSTNAME'}:$ARGV[1]?$ARGV[1]:"Unknown Host";
        print "Set InitialDateTime [${InitialDateTime}]\n";
     }
     $FinalDateTime = $fileDate;
#print $FinalDateTime;

#Date-Time,HOSTNAME, Apache80, Apache80TW, Apache443, Apache443TW, Apache10443, Apache10443TW, Apache20443, Apache20443TW,
# SSB1_OHS_9075, SSB2_OHS_9075, SSB3_OHS_9075, SSB4_OHS_9075, SSB1_OHS_9075CW, SSB2_OHS_9075CW, SSB3_OHS_9075CW, SSB4_OHS_9075CW, 
# SSB1_WLS_7003, SSB2_WLS_7003, SSB3_WLS_7003, SSB4_WLS_7003, SSB1_WLS_7003CW, SSB2_WLS_7003CW, SSB3_WLS_7003CW, SSB4_WLS_7003CW
# SSB1_WLS_9203, SSB2_WLS_9203, SSB3_WLS_9203, SSB4_WLS_9203, SSB1_WLS_9203CW, SSB2_WLS_9203CW, SSB3_WLS_9203CW, SSB4_WLS_9203CW,
# loadAvg1,loadAvg5,loadAvg5,ReqsPerSec,ReqsInProc,IdleWorker

     push(@Apache_80,        $row->{'Apache_80'}?$row->{'Apache_80'}:  $row->{'Apache80'}? $row->{'Apache80'}:0 ); 
    # $Apache_80[#$Apache_80]

#timestamp  
#service.agent.ssb.web1.apache80.
#value

     push(@Apache_80_TW,     $row->{'Apache_80_TW'}? $row->{'Apache_80_TW'}:  $row->{'Apache80TW'}? $row->{'Apache80TW'}:0 ); 
     push(@Apache_443,       $row->{'Apache_443'}?$row->{'Apache_443'}: $row->{'Apache443'}? $row->{'Apache443'}:0 ); 
     push(@Apache_443_TW,    $row->{'Apache_443_TW'}?$row->{'Apache_443_TW'}:  $row->{'Apache443TW'}? $row->{'Apache443TW'}:0 );

     push(@Apache_10443,     $row->{'Apache_10443'}?$row->{'Apache_10443'}: $row->{'Apache10443'}?$row->{'Apache10443'}:0 ); 
     push(@Apache_10443_TW,  $row->{'Apache_10443_TW'}?$row->{'Apache_10443_TW'}: $row->{'Apache10443TW'}?$row->{'Apache10443TW'}:0 );
     push(@Apache_20443,     $row->{'Apache_20443'}? $row->{'Apache_20443'}: $row->{'Apache20443'}?$row->{'Apache20443'}:0 ); 
     push(@Apache_20443_TW,  $row->{'Apache_20443_TW'}?$row->{'Apache_20443_TW'}: $row->{'Apache20443TW'}?$row->{'Apache20443TW'}: $row->{'Apache20443_20443_TW'}?$row->{'Apache20443_20443_TW'}:0 );

# Date-Time,ApacheProcs,Apache80,Apache80TW,Apache443,Apache443TW,Apache20443,Apache20443TW,SSB1-9085,SSB1-9085CW,SSB2-9085,SSB2-9085CW,SSB3-9085,SSB3-9085CW,SSB4-9085,SSB4-9085CW,LoadAvg_1,LoadAvg_5,LoadAvg_15,ApacheStats

# Date-Time,ApacheProcs,Apache80,Apache80TW,Apache443,Apache443TW,SSB1-9080,SSB1-9080CW,SSB2-9080,SSB2-9080CW,SSB3-9080,SSB3-9080CW,SSB4-9080,SSB4-9080CW
     push(@SSB1_OHS_9075,    $row->{'SSB1_OHS_9075'}?$row->{'SSB1_OHS_9075'}: $row->{'SSB1-9080'}?$row->{'SSB1-9080'}: $row->{'SSB1-9085'}?$row->{'SSB1-9085'}:0 ); 
     push(@SSB2_OHS_9075,    $row->{'SSB2_OHS_9075'}?$row->{'SSB2_OHS_9075'}: $row->{'SSB2-9080'}?$row->{'SSB2-9080'}: $row->{'SSB2-9085'}?$row->{'SSB2-9085'}:0 );
     push(@SSB3_OHS_9075,    $row->{'SSB3_OHS_9075'}?$row->{'SSB3_OHS_9075'}: $row->{'SSB3-9080'}?$row->{'SSB3-9080'}: $row->{'SSB3-9085'}?$row->{'SSB3-9085'}:0); 
     push(@SSB4_OHS_9075,    $row->{'SSB4_OHS_9075'}?$row->{'SSB4_OHS_9075'}: $row->{'SSB4-9080'}?$row->{'SSB4-9080'}: $row->{'SSB4-9085'}?$row->{'SSB4-9085'}:0 );

     push(@SSB1_OHS_9075_CW, $row->{'SSB1_OHS_9075_CW'}?$row->{'SSB1_OHS_9075_CW'}: $row->{'SSB1_OHS_9075CW'}?$row->{'SSB1_OHS_9075CW'}: $row->{'SSB1-9080CW'}?$row->{'SSB1-9080CW'}: $row->{'SSB1-9085CW'}? $row->{'SSB1-9085CW'}:0 ); 
     push(@SSB2_OHS_9075_CW, $row->{'SSB2_OHS_9075_CW'}?$row->{'SSB2_OHS_9075_CW'}: $row->{'SSB2_OHS_9075CW'}?$row->{'SSB2_OHS_9075CW'}: $row->{'SSB2-9080CW'}?$row->{'SSB2-9080CW'}: $row->{'SSB2-9085CW'}? $row->{'SSB2-9085CW'}:0 );
     push(@SSB3_OHS_9075_CW, $row->{'SSB3_OHS_9075_CW'}?$row->{'SSB3_OHS_9075_CW'}: $row->{'SSB3_OHS_9075CW'}?$row->{'SSB3_OHS_9075CW'}: $row->{'SSB3-9080CW'}?$row->{'SSB3-9080CW'}: $row->{'SSB3-9085CW'}? $row->{'SSB3-9085CW'}:0 ); 
     push(@SSB4_OHS_9075_CW, $row->{'SSB4_OHS_9075_CW'}?$row->{'SSB4_OHS_9075_CW'}: $row->{'SSB4_OHS_9075CW'}?$row->{'SSB4_OHS_9075CW'}: $row->{'SSB4-9080CW'}?$row->{'SSB4-9080CW'}: $row->{'SSB4-9085CW'}? $row->{'SSB4-9085CW'}:0 );

     push(@SSB1_WLS_7003,    $row->{'SSB1_WLS_7003'}?$row->{'SSB1_WLS_7003'}:0 ); 
     push(@SSB2_WLS_7003,    $row->{'SSB3_WLS_7003'}?$row->{'SSB2_WLS_7003'}:0 );
     push(@SSB3_WLS_7003,    $row->{'SSB2_WLS_7003'}?$row->{'SSB3_WLS_7003'}:0 ); 
     push(@SSB4_WLS_7003,    $row->{'SSB4_WLS_7003'}?$row->{'SSB4_WLS_7003'}:0 );

     push(@SSB1_WLS_7003_CW, $row->{'SSB1_WLS_7003_CW'}?$row->{'SSB1_WLS_7003_CW'}: $row->{'SSB1_WLS_7003CW'}?$row->{'SSB1_WLS_7003CW'}:0 ); 
     push(@SSB2_WLS_7003_CW, $row->{'SSB2_WLS_7003_CW'}?$row->{'SSB2_WLS_7003_CW'}: $row->{'SSB2_WLS_7003CW'}?$row->{'SSB2_WLS_7003CW'}:0 );
     push(@SSB3_WLS_7003_CW, $row->{'SSB3_WLS_7003_CW'}?$row->{'SSB3_WLS_7003_CW'}: $row->{'SSB3_WLS_7003CW'}?$row->{'SSB3_WLS_7003CW'}:0 ); 
     push(@SSB4_WLS_7003_CW, $row->{'SSB4_WLS_7003_CW'}?$row->{'SSB4_WLS_7003_CW'}: $row->{'SSB4_WLS_7003CW'}?$row->{'SSB4_WLS_7003CW'}:0 );

     push(@SSB1_WLS_9203,    $row->{'SSB1_WLS_9203'}?$row->{'SSB1_WLS_9203'}:0 ); 
     push(@SSB2_WLS_9203,    $row->{'SSB2_WLS_9203'}?$row->{'SSB2_WLS_9203'}:0 );
     push(@SSB3_WLS_9203,    $row->{'SSB2_WLS_9203'}?$row->{'SSB3_WLS_9203'}:0 ); 
     push(@SSB4_WLS_9203,    $row->{'SSB4_WLS_9203'}?$row->{'SSB4_WLS_9203'}:0 );

     push(@SSB1_WLS_9203_CW, $row->{'SSB1_WLS_9203_CW'}?$row->{'SSB1_WLS_9203_CW'}: $row->{'SSB1_WLS_9203CW'}?$row->{'SSB1_WLS_9203CW'}:0 ); 
     push(@SSB2_WLS_9203_CW, $row->{'SSB2_WLS_9203_CW'}?$row->{'SSB2_WLS_9203_CW'}: $row->{'SSB2_WLS_9203CW'}?$row->{'SSB2_WLS_9203CW'}:0 );
     push(@SSB3_WLS_9203_CW, $row->{'SSB3_WLS_9203_CW'}?$row->{'SSB3_WLS_9203_CW'}: $row->{'SSB3_WLS_9203CW'}?$row->{'SSB3_WLS_9203CW'}:0 ); 
     push(@SSB4_WLS_9203_CW, $row->{'SSB4_WLS_9203_CW'}?$row->{'SSB4_WLS_9203_CW'}: $row->{'SSB4_WLS_9203CW'}?$row->{'SSB4_WLS_9203CW'}:0);
#Date-Time,ApacheProcs,Apache80,Apache80TW,Apache443,Apache443TW,SSB1-9080,SSB1-9080CW,SSB2-9080,SSB2-9080CW,SSB3-9080,SSB3-9080CW,SSB4-9080,SSB4-9080CW,
#  LoadAvg_1,LoadAvg_5,LoadAvg_15,ApacheStats


     push(@loadAvg1,         $row->{'loadAvg1'}?$row->{'loadAvg1'}: $row->{'LoadAvg_1'}?$row->{'LoadAvg_1'}:0 );
     push(@loadAvg5,         $row->{'loadAvg5'}? $row->{'loadAvg5'}: $row->{'LoadAvg_5'}?$row->{'LoadAvg_5'}:0 ); 
     push(@loadAvg15,        $row->{'loadAvg15'}?$row->{'loadAvg15'}: $row->{'LoadAvg_15'}?$row->{'LoadAvg_15'}:0);

# loadAvg1,loadAvg5,loadAvg5,ReqsPerSec,ReqsInProc,IdleWorker
     push(@ReqPerSec,        $row->{'ReqPerSec'}?$row->{'ReqPerSec'}: $row->{'RecPerSec'}?$row->{'RecPerSec'}: $row->{'ReqsPerSec'}?$row->{'ReqsPerSec'}:0 ); 
     push(@BusyHTTP,         $row->{'BusyHTTP'}? $row->{'BusyHTTP'}: $row->{'ReqsInProc'}?$row->{'ReqsInProc'}:0 ); 
     push(@IdleWorkers,      $row->{'IdleWorkers'}? $row->{'IdleWorkers'}: $row->{'IdleWorker'}?$row->{'IdleWorker'}:0 );

     
#     print $row->{DateTime} ."   ". $row->{'Apache_20443_TW'} . "\n";
      print '.';

     }
print "\n";
print $DataServerName;
my $graphite_string;
foreach my $value (@TimeSeries)
{
#print $value."\n";
date_Epoch($value);
}
my $Apache_80_data;
my $Apache_80_TW_data;
my $Apache_443_data;
my $Apache_443_TW_data;
my $Apache_10443_data;
my $Apache_10443_TW_data;
my $Apache_20443_data;
my $Apache_20443_TW_data, $SSB1_OHS_9075_data, $SSB1_OHS_9075_CW_data, $SSB2_OHS_9075_data, $SSB2_OHS_9075_CW_data, $SSB3_OHS_9075_data, $SSB3_OHS_9075_CW_data, $SSB4_OHS_9075_data, $SSB4_OHS_9075_CW_data,$SSB1_WLS_7003_data, $SSB1_WLS_7003_CW_data, $SSB2_WLS_7003_data, $SSB2_WLS_7003_CW_data, $SSB3_WLS_7003_data, $SSB3_WLS_7003_CW_data, $SSB4_WLS_7003_data, $SSB4_WLS_7003_CW_data, $SSB1_WLS_9203_data, $SSB1_WLS_9203_CW_data, $SSB2_WLS_9203_data, $SSB2_WLS_9203_CW_data, $SSB3_WLS_9203_data, $SSB3_WLS_9203_CW_data, $SSB4_WLS_9203_data , $SSB4_WLS_9203_CW_data, $loadAvg1_data, $loadAvg5_data, $loadAvg15_data, $ReqPerSec_data, $BusyHTTP_data, $IdleWorkers_data;

for(my $i = 0; $i <= $#epoch_array; $i++)
{
$Apache_80_data .= "test.prod.web1.tcp.Apache.80.EST" . "\t" . $Apache_80[$i] . "\t" . $epoch_array[$i] . "\n";
#print $Apache_80_data;
$Apache_80_TW_data .= "test.prod.web1.tcp.Apache.80.TW" . "\t" . $Apache_80_TW[$i] . "\t" . $epoch_array[$i]. "\n";
#print $Apache_80_TW_data;
$Apache_443_data .= "test.prod.web1.tcp.Apache.443.EST" . "\t" . $Apache_443[$i] . "\t" . $epoch_array[$i]. "\n";
#print $Apache_443_data;
$Apache_443_TW_data .= "test.prod.web1.tcp.Apache.443.TW" . "\t" . $Apache_443_TW[$i] . "\t" . $epoch_array[$i]. "\n";
#print $Apache_443_TW_data;
$Apache_10443_data .= "test.prod.web1.tcp.Apache.10443.EST" . "\t" . $Apache_10443[$i] . "\t" . $epoch_array[$i]. "\n";
#print $Apache_10443_data;
$Apache_10443_TW_data .= "test.prod.web1.tcp.Apache.10443.TW" . "\t" . $Apache_10443_TW[$i] . "\t" . $epoch_array[$i]. "\n";
#print $Apache_10443_TW_data;
$Apache_20443_data .= "test.prod.web1.tcp.Apache.20443.EST" . "\t" . $Apache_20443[$i] . "\t" . $epoch_array[$i]. "\n";
#print $Apache_20443_data;
$Apache_20443_TW_data .= "test.prod.web1.tcp.Apache.20443.TW" . "\t" . $Apache_20443_TW[$i] . "\t" . $epoch_array[$i]. "\n";
#print $Apache_20443_TW_data;
$SSB1_OHS_9075_data .= "test.prod.web1.tcp.SSB1.OHS.9075.EST" . "\t" . $SSB1_OHS_9075[$i] . "\t" . $epoch_array[$i]. "\n";
#print $SSB1_OHS_9075_data;
$SSB1_OHS_9075_CW_data .= "test.prod.web1.tcp.SSB1.OHS.9075.CW" . "\t" . $SSB1_OHS_9075_CW[$i] . "\t" . $epoch_array[$i]. "\n";
#print $SSB1_OHS_9075_CW_data;
$SSB2_OHS_9075_data .= "test.prod.web1.tcp.SSB2.OHS.9075.EST" . "\t" . $SSB2_OHS_9075[$i] . "\t" . $epoch_array[$i]. "\n";
#print $SSB2_OHS_9075_data;
$SSB2_OHS_9075_CW_data .= "test.prod.web1.tcp.SSB2.OHS.9075.CW" . "\t" . $SSB2_OHS_9075_CW[$i] . "\t" . $epoch_array[$i]. "\n";
#print $SSB2_OHS_9075_CW_data;
$SSB3_OHS_9075_data .= "test.prod.web1.tcp.SSB3.OHS.9075.EST" . "\t" . $SSB3_OHS_9075[$i] . "\t" . $epoch_array[$i]. "\n";
#print $SSB3_OHS_9075_data;
$SSB3_OHS_9075_CW_data .= "test.prod.web1.tcp.SSB3.OHS.9075.CW" . "\t" . $SSB3_OHS_9075_CW[$i] . "\t" . $epoch_array[$i]. "\n";
#print $SSB3_OHS_9075_CW_data;
$SSB4_OHS_9075_data .= "test.prod.web1.tcp.SSB4.OHS.9075.EST" . "\t" . $SSB4_OHS_9075[$i] . "\t" . $epoch_array[$i]. "\n";
#print $SSB4_OHS_9075_data;
$SSB4_OHS_9075_CW_data .= "test.prod.web1.tcp.SSB4.OHS.9075.CW" . "\t" . $SSB4_OHS_9075_CW[$i] . "\t" . $epoch_array[$i]. "\n";
#print $SSB4_OHS_9075_CW_data;
$SSB1_WLS_7003_data .= "test.prod.web1.tcp.SSB1.WLS.7003.EST" . "\t" . $SSB1_WLS_7003[$i] . "\t" . $epoch_array[$i] . "\n";
#print $SSB1_WLS_7003_data;
$SSB1_WLS_7003_CW_data .= "test.prod.web1.tcp.SSB1.WLS.7003.CW" . "\t" . $SSB1_WLS_7003_CW[$i] . "\t" . $epoch_array[$i] . "\n";
#print $SSB1_WLS_7003_CW_data;
$SSB2_WLS_7003_data .= "test.prod.web1.tcp.SSB2.WLS.7003.EST" . "\t" . $SSB2_WLS_7003[$i] . "\t" . $epoch_array[$i] . "\n";
#print $SSB2_WLS_7003_data;
$SSB2_WLS_7003_CW_data .= "test.prod.web1.tcp.SSB2.WLS.7003.CW" . "\t" . $SSB2_WLS_7003_CW[$i] . "\t" . $epoch_array[$i] . "\n";
#print $SSB2_WLS_7003_CW_data;
$SSB3_WLS_7003_data .= "test.prod.web1.tcp.SSB3.WLS.7003.EST" . "\t" . $SSB3_WLS_7003[$i] . "\t" . $epoch_array[$i] . "\n";
#print $SSB3_WLS_7003_data;
$SSB3_WLS_7003_CW_data .= "test.prod.web1.tcp.SSB3.WLS.7003.CW" . "\t" . $SSB3_WLS_7003_CW[$i] . "\t" . $epoch_array[$i] . "\n";
#print $SSB3_WLS_7003_CW_data;
$SSB4_WLS_7003_data .= "test.prod.web1.tcp.SSB4.WLS.7003.EST" . "\t" . $SSB4_WLS_7003[$i] . "\t" . $epoch_array[$i] . "\n";
#print $SSB4_WLS_7003_data;
$SSB4_WLS_7003_CW_data .= "test.prod.web1.tcp.SSB4.WLS.7003.CW" . "\t" . $SSB4_WLS_7003_CW[$i] . "\t" . $epoch_array[$i] . "\n";
#print $SSB4_WLS_7003_CW_data;
$SSB1_WLS_9203_data .= "test.prod.web1.tcp.SSB1.WLS.9203.EST" . "\t" . $SSB1_WLS_9203[$i] . "\t" . $epoch_array[$i] . "\n";
#print $SSB1_WLS_9203_data;
$SSB1_WLS_9203_CW_data .= "test.prod.web1.tcp.SSB1.WLS.9203.CW" . "\t" . $SSB1_WLS_9203_CW[$i] . "\t" . $epoch_array[$i] . "\n";
#print $SSB1_WLS_9203_CW_data;
$SSB2_WLS_9203_data .= "test.prod.web1.tcp.SSB2.WLS.9203.EST" . "\t" . $SSB2_WLS_9203[$i] . "\t" . $epoch_array[$i] . "\n";
#print $SSB2_WLS_9203_data;
$SSB2_WLS_9203_CW_data .= "test.prod.web1.tcp.SSB2.WLS.9203.CW" . "\t" . $SSB2_WLS_9203_CW[$i] . "\t" . $epoch_array[$i] . "\n";
#print $SSB2_WLS_9203_CW_data;
$SSB3_WLS_9203_data .= "test.prod.web1.tcp.SSB3.WLS.9203.EST" . "\t" . $SSB3_WLS_9203[$i] . "\t" . $epoch_array[$i] . "\n";
#print $SSB3_WLS_9203_data;
$SSB3_WLS_9203_CW_data .= "test.prod.web1.tcp.SSB3.WLS.9203.CW" . "\t" . $SSB3_WLS_9203_CW[$i] . "\t" . $epoch_array[$i] . "\n";
#print $SSB3_WLS_9203_CW_data;
$SSB4_WLS_9203_data .= "test.prod.web1.tcp.SSB4.WLS.9203.EST" . "\t" . $SSB4_WLS_9203[$i] . "\t" . $epoch_array[$i] . "\n";
#print $SSB4_WLS_9203_data;
$SSB4_WLS_9203_CW_data .= "test.prod.web1.tcp.SSB4.WLS.9203.CW" . "\t" . $SSB4_WLS_9203_CW[$i] . "\t" . $epoch_array[$i] . "\n";
#print $SSB4_WLS_9203_CW_data;
$loadAvg1_data .= "test.prod.web1.tcp.loadAvg1" . "\t" . $loadAvg1[$i] . "\t" . $epoch_array[$i] . "\n";
#print $loadAvg1_data;
$loadAvg5_data .= "test.prod.web1.tcp.loadAvg5" . "\t" . $loadAvg5[$i] . "\t" . $epoch_array[$i] . "\n";
#print $loadAvg5_data;
$loadAvg15_data .= "test.prod.web1.tcp.loadAvg15" . "\t" . $loadAvg15[$i] . "\t" . $epoch_array[$i] . "\n";
#print $loadAvg15_data;
$ReqPerSec_data .= "test.prod.web1.tcp.ReqPerSec" . "\t" . $ReqPerSec[$i] . "\t" . $epoch_array[$i] . "\n";
#print $ReqPerSec_data;
$BusyHTTP_data .= "test.prod.web1.tcp.BusyHTTP" . "\t" . $BusyHTTP[$i] . "\t" . $epoch_array[$i] . "\n";
#print $BusyHTTP_data;
$IdleWorkers_data .= "test.prod.web1.tcp.IdleWorkers" . "\t" . $IdleWorkers[$i] . "\t" . $epoch_array[$i] . "\n";
#print $IdleWorkers_data;
$testdata = "test.vm223.tcp.Est.80" . "\t" . 1 . "\t" . time;
$testdata .= "test.vm223.tcp.Est.80" . "\t" . 2 . "\t" . time + 600;
$graphite_string .= $Apache_80_data . $Apache_80_TW_data . $Apache_443_data . $Apache_443_TW_data . $Apache_10443_data . $Apache_10443_TW_data . $Apache_20443_data . $Apache_20443_TW_data . $SSB1_OHS_9075_data . $SSB1_OHS_9075_CW_data . $SSB2_OHS_9075_data . $SSB2_OHS_9075_CW_data . $SSB3_OHS_9075_data . $SSB3_OHS_9075_CW_data . $SSB4_OHS_9075_data . $SSB4_OHS_9075_CW_data . $SSB1_WLS_7003_data . $SSB1_WLS_7003_CW_data . $SSB2_WLS_7003_data . $SSB2_WLS_7003_CW_data . $SSB3_WLS_7003_data . $SSB3_WLS_7003_CW_data . $SSB4_WLS_7003_data . $SSB4_WLS_7003_CW_data . $SSB1_WLS_9203_data . $SSB1_WLS_9203_CW_data . $SSB2_WLS_9203_data . $SSB2_WLS_9203_CW_data . $SSB3_WLS_9203_data . $SSB3_WLS_9203_CW_data . $SSB4_WLS_9203_data . $SSB4_WLS_9203_CW_data . $loadAvg1_data . $loadAvg5_data . $loadAvg15_data . $ReqPerSec_data . $BusyHTTP_data . $IdleWorkers_data
}
send_data($graphite_string);
}
#foreach my $value (@epoch_array)
#{print $value."\n";}
#foreach my $value (@Apache_443)
#{print $value."\n";}
#
#  Looping can end here
#

#
#  Program ENDS here

# subroutines

sub date_Epoch
{
        my ($date);
        ($date) = @_;
        my $parser = DateTime::Format::Strptime->new(
                pattern => '%m/%d/%Y %H:%M:%S',
                on_error => 'croak',
                );

        my $dt = $parser->parse_datetime($date);
        push(@epoch_array,$dt->epoch);
}

sub send_data
{
   # BEGIN { $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0 }
   # my $ua = LWP::UserAgent->new;
   # my $server_address = "https://nagios-test.example.com/cgi-bin/post_cgi.pl";
   # my $request = HTTP::Request->new( POST => $server_address);
   # my $post_data = {"data"=> @_};
   # $request->header('content-type' => 'application/json');
   # my $response = $ua->post( $server_address, $post_data );    
   # if($response->is_success){
   #     my $message = $response->decoded_content();
   #     print "Reply : $message\n";
   # }
   # else{
   #     print "HTTP POST Error Code: ", $response->code, "\n";
   #     print "HTTP POST Error Message: ", $response->message, "\n";
   # }


    my ($data) = @_;
    my $carbon_address = '127.0.0.1';
    my $carbon_port = '2003';
    my $protocol = 'tcp';
    my $socket = new IO::Socket::INET(PeerAddr => $carbon_address, PeerPort => $carbon_port, Proto => $protocol);
    $socket or die "No socket: $!";
    $socket->send($data);
    close($socket);
}
sub time_hourFormat
{
  my $param1 = shift;
  my $ret = substr( $param1, 0, 2 );

# print "$value\n";
        return "A String";
}

sub TimeStamp 
{
   my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime( time );
   $year += 1900; $mon += 1;
   my $TimeStamp  = sprintf( "%2.2d/%2.2d/%4.4d %2.2d:%2.2d:%2.2d", $mon, $mday, $year, $hour, $min, $sec );
   return $TimeStamp;
}

sub DateStamp
{
   my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime( time );
   $year += 1900; $mon += 1;
   my $DateStamp  = sprintf( "%2.2d/%2.2d/%4.4d", $mon, $mday, $year );
   return $DateStamp;
}

sub FileDateStamp
{
   my ($t) = @_;
   my ($r);
   if (! ($t) ) {
      my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime( time );
      $year += 1900; $mon += 1;
      $r = sprintf( "%4.4d%2.2d%2.2d", $year, $mon, $mday );
   } else {
     # We have a  "%2.2d/%2.2d/%4.4d" incoming formattted data....
     $r = $t;
     if ( !( $r =~ s/([0-9]{2})\/([0-9]{2})\/([0-9]{4}).*/$3$2$1/g ) ) {
       $r =~ s/([0-9]{2})\/([0-9]{2})\/([0-9]{2}).*/$3$2$1/g
      };
   }
   return $r;
}



