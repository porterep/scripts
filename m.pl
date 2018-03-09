#!/usr/bin/perl
use IO::Socket::INET;
use constant false => 0;
use constant true  => 1;
use constant field_separator => "|";
use LWP::UserAgent;

#Graphite related variables...
my $timeNow = time;
my $enviro = $ARGV[0];

#Check for command line arguments
if(($#ARGV + 1) < 1 )
{
  print "\nYou must include an environment name.\n";
  exit 1;
} 



# Command Line
my ($attribs)=@ARGV;

# used file handles
my $fhoutfile;
my $OutputFilePath = "/home/bcrayton/nagios/logs";
my $OutFile;

# the following are defined for QA
my ($SSB1Address,$SSB2Address,$SSB3Address,$SSB4Address) = ("10.55.24.138","10.55.24.139","10.55.24.152","10.55.24.153");
my ($OHSPort,$CascadePort,$SSOMGRPort) = ("9075","7003","9203");
my ($ApachePort80, $ApachePort443, $ApachePort10443, $ApachePort20443) = ("80","443","10443","20443");

# Local Status of interest:  ESTABLISHED TIME_WAIT LISTEN
# Remote Status of interest: ESTABLISHED CLOSE_WAIT SYN_SENT

# For sending to Nagios
my $NagioCMD="send_nsca.pl -H nagios-test.example.com";

# Get local IP Address from eth0

my @IfConfig = qx{ /sbin/ifconfig eth0 };
my $ServerIPv4="", $ServerIPv6="";
for my $line (@IfConfig) {
  if (  $line =~ s/\s+inet6 addr: ([a-zA-Z0-9:\/]{8,64}).*/\1/ ) {
   $ServerIPv6 =   $line; $ServerIPv6 =~ s/ |\n//g;
   print "IPv6 Address : ". $ServerIPv6 . "\n";
  }
  if (  $line =~ s/.*addr:([0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}).*/\1/ ) {
   $ServerIPv4 =   $line;  $ServerIPv4 =~ s/ |\n//g;
   print "IPv4 Address : ".  $ServerIPv4 ."\n";
  }
}

# Get hostname prefix (ignore domain portion)
my $HostName = qx{ echo \$HOSTNAME };
$HostName =~ s/([A-Za-z0-9_]+)\..*/\1/; $HostName =~ s/ |\n//g;
print "HostName : [". $HostName . "]\n";

# If we had a main iteration loop, it should begin here


my $DateStamp = qx{ date +%Y%m%d%H%M };
$DateStamp =~ s/\n//g;
print "DateStamp : " . $DateStamp . "\n";


# Create target output file name
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime( time );
$year += 1900; $mon += 1;
my $TimeStamp  = sprintf( "%2.2d/%2.2d/%4.4d %2.2d:%2.2d:%2.2d", $mon, $mday, $year, $hour, $min, $sec );
my $SimpleDate = sprintf( "%4.4d%2.2d%2.2d", $year, $mon, $mday ); 

$OutFile = $OutputFilePath . '/' . $HostName . "-" . $SimpleDate . "-webstats.csv";

print "OutFile Name : [" . $OutFile . "]\n";

if ( -d $OutputFilePath ) {
  # print "Output file path exists";
} else {
  print "Output file path does not exist";
}

my $NeedFileheader = false;

#If the file does not exist or is Zero bytes, we need a header
if (( ! -e $OutFile ) || ( -z $OutFile )) {  $NeedFileheader = true; }

# Open Log file here for Appending
 #open( $fhoutfile, ">> $OutFile") || die 'Could not open target file' ;

my $FileHeader = "DateTime,Hostname,"
         ."Apache_${ApachePort80},Apache_${ApachePort80}_TW,Apache_${ApachePort443},Apache_${ApachePort443}_TW,"
         ."Apache_${ApachePort10443},Apache_${ApachePort10443}_TW,Apache_${ApachePort20443},Apache_${ApachePort20443}_TW,"

# SSB1_OHS_9075,SSB2_OHS_9075,SSB3_OHS_9075,SSB4_OHS_9075,SSB1_OHS_9075CW,SSB2_OHS_9075CW,SSB3_OHS_9075CW,SSB4_OHS_9075CW,
         ."SSB1_OHS_${OHSPort},SSB2_OHS_${OHSPort},SSB3_OHS_${OHSPort},SSB4_OHS_${OHSPort},"
         ."SSB1_OHS_${OHSPort}_CW,SSB2_OHS_${OHSPort}_CW,SSB3_OHS_${OHSPort}_CW,SSB4_OHS_${OHSPort}_CW,"

# WebLogic CascadeU
# SSB1_WLS_7003,SSB2_WLS_7003,SSB3_WLS_7003,SSB4_WLS_7003,SSB1_WLS_7003CW,SSB2_WLS_7003CW,SSB3_WLS_7003CW,SSB4_WLS_7003CW
         ."SSB1_WLS_${CascadePort},SSB2_WLS_${CascadePort},SSB3_WLS_${CascadePort},SSB4_WLS_${CascadePort},"
         ."SSB1_WLS_${CascadePort}_CW,SSB2_WLS_${CascadePort}_CW,SSB3_WLS_${CascadePort}_CW,SSB4_WLS_${CascadePort}_CW,"

# WebLogic SSOMGR
# SSB1_WLS_9203,SSB2_WLS_9203,SSB3_WLS_9203,SSB4_WLS_9203,SSB1_WLS_9203CW,SSB2_WLS_9203CW,SSB3_WLS_9203CW,SSB4_WLS_9203CW
         ."SSB1_WLS_${SSOMGRPort},SSB2_WLS_${SSOMGRPort},SSB3_WLS_${SSOMGRPort},SSB4_WLS_${SSOMGRPort},"
         ."SSB1_WLS_${SSOMGRPort}_CW,SSB2_WLS_${SSOMGRPort}_CW,SSB3_WLS_${SSOMGRPort}_CW,SSB4_WLS_${SSOMGRPort}_CW"

# System Statistics
         .",loadAvg1,loadAvg5,loadAvg15,ReqPerSec,BusyHTTP,IdleWorkers"         
         ;

#print $FileHeader . "\n";

if ( $NeedFileheader ) {
  # print $fhoutfile  $FileHeader . "\n";  
} 

# Gather Network Statistics
my @netstatLines = qx{ /bin/netstat -tna };
#print( $netstatLines[0] );

my $upTime = qx{ uptime };
$upTime =~ s/.*load average: (.*)$/\1/; $upTime =~ s/ |\n//g;
my ($loadAvg1, $loadAvg5, $loadAvg15 ) = split /,/,  $upTime;

print "Current Load Avg1 [${loadAvg1}] Avg5 [${loadAvg5}] Avg15 [${loadAvg15}]\n";

my @serverInfo = qx{ curl -s http://127.0.0.1:50080/server-status };
my $RequestsPerSec; my $RequestsInProc; my $IdleWorkers;
for my $Infoline  (@serverInfo) {
  if ( $Infoline =~ s/.*>([0-9]{0,4}.{0,1}[0-9]{1,4}) requests\/sec.*/\1/g ) {
     $Infoline =~ s/ |\n//g;
     print "Req Per Sec :[${Infoline}]\n";
     $RequestsPerSec = ${Infoline};
  }
  if ( $Infoline =~ s/.*([0-9]{0,4}.{0,1}[0-9]{1,4}) requests currently being processed, ([0-9]{0,4}.{0,1}[0-9]{1,4}) idle.*/\1 \2/ ) {
#     print "RequestInProc & IdleWorkder :[${$Infoline}]\n";
     $Infoline =~ s/\n//g;
     ($RequestsInProc, $IdleWorkers) = split / /, $Infoline;
     print "RequestsInProc :[${RequestsInProc}] IdleWorkers :[${IdleWorkers}]\n";
  }
}

# Back End Stats
my $SSB1_OHS = 0,     $SSB2_OHS = 0,     $SSB3_OHS = 0,     $SSB4_OHS = 0;
my $SSB1_CASCADE = 0, $SSB2_CASCADE = 0, $SSB3_CASCADE = 0, $SSB4_CASCADE = 0;
my $SSB1_SSOMGR = 0,  $SSB2_SSOMGR = 0,  $SSB3_SSOMGR = 0,  $SSB4_SSOMGR = 0;

my $SSB1_OHS_CW = 0,     $SSB2_OHS_CW = 0,     $SSB3_OHS_CW = 0,     $SSB4_OHS_CW = 0;
my $SSB1_CASCADE_CW = 0, $SSB2_CASCADE_CW = 0, $SSB3_CASCADE_CW = 0, $SSB4_CASCADE_CW = 0;
my $SSB1_SSOMGR_CW = 0,  $SSB2_SSOMGR_CW = 0,  $SSB3_SSOMGR_CW = 0,  $SSB4_SSOMGR_CW = 0;

# Front End Stats
my $Apache80 = 0,    $Apache443 = 0,    $Apache10443 = 0,    $Apache20443 = 0;
my $Apache80_TW = 0, $Apache443_TW = 0, $Apache10443_TW = 0, $Apache20443_TW = 0;
my $Apache80_LISTEN = false, $Apache443_LISTEN = false, $Apache10443_LISTEN = false, $Apache20443_LISTEN = false;

for my $line (@netstatLines) {
    my @element = split /\s+/, $line;
    next unless $line =~ /^tcp/; 

# Last index of : will delimit the Port from Ip Address
    my ($LocalAddress,$LocalPort)   = (substr( $element[3], 0, rindex($element[3],':') ), substr($element[3],rindex($element[3],':')+1));
    my ($RemoteAddress,$RemotePort) = (substr( $element[4], 0, rindex($element[4],':') ), substr($element[4],rindex($element[4],':')+1));
    my ($State) = $element[5];
    my ($Protocol) = $element[0];

    if ($Protocol eq 'tcp' ) {

     if ( $State eq 'LISTEN' ) {
      # print( " LISTEN Local A:P [".$LocalAddress . "]:[" .$LocalPort."]   Remote A:P [" . $RemoteAddress ."]:[". $RemotePort ."]\n" );
        if ( $LocalPort eq $ApachePort80 )    {  $Apache80_LISTEN    = true; }
        if ( $LocalPort eq $ApachePort443 )   {  $Apache443_LISTEN   = true; }
        if ( $LocalPort eq $ApachePort10443 ) {  $Apache10443_LISTEN = true; }
        if ( $LocalPort eq $ApachePort20443 ) {  $Apache20443_LISTEN = true; }
      }

      if ( $State eq 'ESTABLISHED' ) {
       # print( "ESTABLISHED Local A:P [".$LocalAddress . "]:[" .$LocalPort."]   Remote A:P [" . $RemoteAddress ."]:[". $RemotePort ."]\n" );
       # Local ESTABLISHED PORTS (Others connected to me)
       if ( $ServerIPv4 eq $LocalAddress ) {
        if ( $LocalPort eq $ApachePort80 )    { $Apache80++;    }
        if ( $LocalPort eq $ApachePort443 )   { $Apache443++;   }
        if ( $LocalPort eq $ApachePort10443 ) { $Apache10443++; }
        if ( $LocalPort eq $ApachePort20443 ) { $Apache20443++; }
       } # End If Locally Established Connections

      # Remote ESTABLISHED PORTS (I connected to these)
      if ( $SSB1Address eq $RemoteAddress ) {  
       if ( $RemotePort eq $OHSPort )     { $SSB1_OHS++;    }
       if ( $RemotePort eq $CascadePort ) { $SSB1_CASCADE++;}
       if ( $RemotePort eq $SSOMGRPort )  { $SSB1_SSOMGR++; }
      }
      if ( $SSB2Address eq $RemoteAddress ) {  
       if ( $RemotePort eq $OHSPort )     { $SSB2_OHS++;    }
       if ( $RemotePort eq $CascadePort ) { $SSB2_CASCADE++;}
       if ( $RemotePort eq $SSOMGRPort )  { $SSB2_SSOMGR++; }
      }
      if ( $SSB3Address eq $RemoteAddress ) {  
       if ( $RemotePort eq $OHSPort )     { $SSB3_OHS++;    }
       if ( $RemotePort eq $CascadePort ) { $SSB3_CASCADE++;}
       if ( $RemotePort eq $SSOMGRPort )  { $SSB3_SSOMGR++; }
      }
      if ( $SSB4Address eq $RemoteAddress ) {  
       if ( $RemotePort eq $OHSPort )     { $SSB4_OHS++;    }
       if ( $RemotePort eq $CascadePort ) { $SSB4_CASCADE++;}
       if ( $RemotePort eq $SSOMGRPort )  { $SSB4_SSOMGR++; }
      }
      } # End If Established Connections

     if ( $State =~ /TIME_WAIT/ ) {
      # Local TIME_WAIT PORTS
      # print( " TIME_WAIT Local A:P [".$LocalAddress . "]:[" .$LocalPort."]   Remote A:P [" . $RemoteAddress ."]:[". $RemotePort ."]\n" );
       if ( $ServerIPv4 eq $LocalAddress ) {
        if ( $LocalPort eq $ApachePort80 )    { $Apache80_TW++;    }
        if ( $LocalPort eq $ApachePort443 )   { $Apache443_TW++;   }
        if ( $LocalPort eq $ApachePort10443 ) { $Apache10443_TW++; }
        if ( $LocalPort eq $ApachePort20443 ) { $Apache20443_TW++; }
       } # End If Locally Established Connections
     }

     if ( $State =~ /CLOSE_WAIT/ ) {
      # Remote CLOSE_WAIT PORTS
      if ( $SSB1Address eq $RemoteAddress ) {
       # print "SSB1 CW detected  1:[${SSB1Address}] 2:[${SSB2Address}] 3:[${SSB3Address}] 4:[${SSB4Address}]\n";
       if ( $RemotePort eq $OHSPort )     { $SSB1_OHS_CW++;    }
       if ( $RemotePort eq $CascadePort ) { $SSB1_CASCADE_CW++;}
       if ( $RemotePort eq $SSOMGRPort )  { $SSB1_SSOMGR_CW++; }
      }
      if ( $SSB2Address eq $RemoteAddress ) {
       # print "SSB2 CW detected \n";
       if ( $RemotePort eq $OHSPort )     { $SSB2_OHS_CW++;    }
       if ( $RemotePort eq $CascadePort ) { $SSB2_CASCADE_CW++;}
       if ( $RemotePort eq $SSOMGRPort )  { $SSB2_SSOMGR_CW++; }
      }
      if ( $SSB3Address eq $RemoteAddress ) {
       if ( $RemotePort eq $OHSPort )     { $SSB3_OHS_CW++;    }
       if ( $RemotePort eq $CascadePort ) { $SSB3_CASCADE_CW++;}
       if ( $RemotePort eq $SSOMGRPort )  { $SSB3_SSOMGR_CW++; }
      }
      if ( $SSB4Address eq $RemoteAddress ) {
       if ( $RemotePort eq $OHSPort )     { $SSB4_OHS_CW++;    }
       if ( $RemotePort eq $CascadePort ) { $SSB4_CASCADE_CW++;}
       if ( $RemotePort eq $SSOMGRPort )  { $SSB4_SSOMGR_CW++; }
      }
     }
     if ( $State =~ /SYN_SENT/ ) {}

#    print( "Local A:P [".$LocalAddress . "]:[" .$LocalPort."]   Remote A:P [" . $RemoteAddress ."]:[". $RemotePort ."]\n" );

    } # End If $Protocol eq tcp

} # End For Loop of Netstat data

# Done collecting Stats, now right data to file in HEADER order.
##Declare data variables
my $Apache_80_data = "$enviro.$HostName.Inbound.TCP.80.EST" . "\t" . $Apache80 . "\t" . $timeNow . "\n";
my $Apache_80_TW_data = "$enviro.$HostName.Inbound.TCP.80.TW" . "\t" . $Apache80_TW . "\t" . $timeNow . "\n";
my $Apache_443_data = "$enviro.$HostName.Inbound.TCP.443.EST" . "\t" . $Apache443 . "\t" . $timeNow . "\n";
my $Apache_443_TW_data = "$enviro.$HostName.Inbound.TCP.443.TW" . "\t" . $Apache443_TW . "\t" . $timeNow . "\n";
my $Apache_10443_data = "$enviro.$HostName.Inbound.TCP.10443.EST" . "\t" . $Apache10443 . "\t" . $timeNow . "\n";
my $Apache_10443_TW_data = "$enviro.$HostName.Inbound.TCP.10443.TW" . "\t" . $Apache10443_TW . "\t" . $timeNow . "\n";
my $Apache_20443_data = "$enviro.$HostName.Inbound.TCP.20443.EST" . "\t" . $Apache20443 . "\t" . $timeNow . "\n";
my $Apache_20443_TW_data = "$enviro.$HostName.Inbound.TCP.20443.TW" . "\t" . $Apache20443_TW . "\t" . $timeNow . "\n";
my $SSB1_OHS_9075_data = "$enviro.$HostName.Outbound.TCP.9075.EST" . "\t" . $SSB1_OHS . "\t" . $timeNow . "\n";
my $SSB1_OHS_9075_CW_data = "$enviro.$HostName.Outbound.TCP.9075.CW" . "\t" . $SSB1_OHS_CW . "\t" . $timeNow . "\n";
my $SSB2_OHS_9075_data = "$enviro.$HostName.Outbound.TCP.9075.EST" . "\t" . $SSB2_OHS . "\t" . $timeNow . "\n";
my $SSB2_OHS_9075_CW_data = "$enviro.$HostName.Outbound.TCP.9075.CW" . "\t" . $SSB2_OHS_CW . "\t" . $timeNow . "\n";
my $SSB3_OHS_9075_data = "$enviro.$HostName.Outbound.TCP.9075.EST" . "\t" . $SSB3_OHS . "\t" . $timeNow . "\n";
my $SSB3_OHS_9075_CW_data = "$enviro.$HostName.Outbound.TCP.9075.CW" . "\t" . $SSB3_OHS_CW . "\t" . $timeNow . "\n";
my $SSB4_OHS_9075_data = "$enviro.$HostName.Outbound.TCP.9075.EST" . "\t" . $SSB4_OHS . "\t" . $timeNow . "\n";
my $SSB4_OHS_9075_CW_data = "$enviro.$HostName.Outbound.TCP.9075.CW" . "\t" . $SSB4_OHS_CW . "\t" . $timeNow . "\n";
my $SSB1_WLS_7003_data = "$enviro.$HostName.Outbound.TCP.7003.EST" . "\t" . $SSB1_CASCADE . "\t" . $timeNow . "\n";
my $SSB1_WLS_7003_CW_data = "$enviro.$HostName.Outbound.TCP.7003.CW" . "\t" . $SSB1_CASCADE_CW . "\t" . $timeNow . "\n";
my $SSB2_WLS_7003_data = "$enviro.$HostName.Outbound.TCP.7003.EST" . "\t" . $SSB2_CASCADE . "\t" . $timeNow . "\n";
my $SSB2_WLS_7003_CW_data = "$enviro.$HostName.Outbound.TCP.7003.CW" . "\t" . $SSB2_CASCADE_CW . "\t" . $timeNow . "\n";
my $SSB3_WLS_7003_data = "$enviro.$HostName.Outbound.TCP.7003.EST" . "\t" . $SSB3_CASCADE . "\t" . $timeNow . "\n";
my $SSB3_WLS_7003_CW_data = "$enviro.$HostName.Outbound.TCP.7003.CW" . "\t" . $SSB3_CASCADE_CW . "\t" . $timeNow . "\n";
my $SSB4_WLS_7003_data = "$enviro.$HostName.Outbound.TCP.7003.EST" . "\t" . $SSB4_CASCADE . "\t" . $timeNow . "\n";
my $SSB4_WLS_7003_CW_data = "$enviro.$HostName.Outbound.TCP.7003.CW" . "\t" . $SSB4_CASCADE_CW . "\t" . $timeNow . "\n";
my $SSB1_WLS_9203_data = "$enviro.$HostName.Outbound.TCP.9203.EST" . "\t" . $SSB1_SSOMGR . "\t" . $timeNow . "\n";
my $SSB1_WLS_9203_CW_data = "$enviro.$HostName.Outbound.TCP.9203.CW" . "\t" . $SSB1_SSOMGR_CW . "\t" . $timeNow . "\n";
my $SSB2_WLS_9203_data = "$enviro.$HostName.Outbound.TCP.9203.EST" . "\t" . $SSB2_SSOMGR . "\t" . $timeNow . "\n";
my $SSB2_WLS_9203_CW_data = "$enviro.$HostName.Outbound.TCP.9203.CW" . "\t" . $SSB2_SSOMGR_CW . "\t" . $timeNow . "\n";
my $SSB3_WLS_9203_data = "$enviro.$HostName.Outbound.TCP.9203.EST" . "\t" . $SSB3_SSOMGR . "\t" . $timeNow . "\n";
my $SSB3_WLS_9203_CW_data = "$enviro.$HostName.Outbound.TCP.9203.CW" . "\t" . $SSB3_SSOMGR_CW . "\t" . $timeNow . "\n";
my $SSB4_WLS_9203_data = "$enviro.$HostName.Outbound.TCP.9203.EST" . "\t" . $SSB4_SSOMGR . "\t" . $timeNow . "\n"; 
my $SSB4_WLS_9203_CW_data = "$enviro.$HostName.Outbound.TCP.9203.CW" . "\t" . $SSB4_SSOMGR_CW . "\t" . $timeNow . "\n";
my $loadAvg1_data = "$enviro.$HostName.LoadAvg.1" . "\t" . $loadAvg1 . "\t" . $timeNow . "\n";
my $loadAvg5_data = "$enviro.$HostName.LoadAvg.5" . "\t" . $loadAvg5 . "\t" . $timeNow . "\n";
my $loadAvg15_data = "$enviro.$HostName.LoadAvg.15" . "\t" . $loadAvg15 . "\t" . $timeNow . "\n";
my $ReqPerSec_data = "$enviro.$HostName.ReqPerSec" . "\t" . $RequestsPerSec . "\t" . $timeNow . "\n";
my $BusyHTTP_data = "$enviro.$HostName.BusyHTTP" . "\t" . $BusyHTTP . "\t" . $timeNow . "\n";
my $IdleWorkers_data = "$enviro.$HostName.IdleWorkers" . "\t" . $IdleWorkers . "\t" . $timeNow . "\n";
my $testdata = "mScript.test.data.post" . "\t" . 10 . "\t" . time() . "\n";

###Send data to graphite
post_data($Apache_80_data);
post_data($Apache_80_TW_data);
post_data($Apache_443_data);
post_data($Apache_443_TW_data);
post_data($Apache_10443_data);
post_data($Apache_10443_TW_data);
post_data($Apache_20443_data);
post_data($Apache_20443_TW_data);
post_data($SSB1_OHS_9075_data);
post_data($SSB1_OHS_9075_CW_data);
post_data($SSB2_OHS_9075_data);
post_data($SSB2_OHS_9075_CW_data);
post_data($SSB3_OHS_9075_data);
post_data($SSB3_OHS_9075_CW_data);
post_data($SSB4_OHS_9075_data);
post_data($SSB4_OHS_9075_CW_data);
post_data($SSB1_WLS_7003_data);
post_data($SSB1_WLS_7003_CW_data);
post_data($SSB2_WLS_7003_data);
post_data($SSB2_WLS_7003_CW_data);
post_data($SSB3_WLS_7003_data);
post_data($SSB3_WLS_7003_CW_data);
post_data($SSB4_WLS_7003_data);
post_data($SSB4_WLS_7003_CW_data);
post_data($SSB1_WLS_9203_data);
post_data($SSB1_WLS_9203_CW_data);
post_data($SSB2_WLS_9203_data);
post_data($SSB2_WLS_9203_CW_data);
post_data($SSB3_WLS_9203_data);
post_data($SSB3_WLS_9203_CW_data);
post_data($SSB4_WLS_9203_data);
post_data($SSB4_WLS_9203_CW_data);
post_data($loadAvg1_data);
post_data($loadAvg5_data);
post_data($loadAvg15_data);
post_data($ReqPerSec_data);
post_data($BusyHTTP_data);
post_data($IdleWorkers_data);
#post_data($testdata);


my $FileDataLine = "${TimeStamp},${HostName},"
         ."${Apache80},${Apache80_TW},${Apache443},${Apache443_TW},"
         ."${Apache10443},${Apache10443_TW},${Apache20443},${Apache20443_TW},"

         ."${SSB1_OHS},${SSB2_OHS},${SSB3_OHS},${SSB4_OHS},"
         ."${SSB1_OHS_CW},${SSB2_OHS_CW},${SSB3_OHS_CW},${SSB4_OHS_CW},"

         ."${SSB1_CASCADE},${SSB2_CASCADE},${SSB3_CASCADE},${SSB4_CASCADE},"
         ."${SSB1_CASCADE_CW},${SSB2_CASCADE_CW},${SSB3_CASCADE_CW},${SSB4_CASCADE_CW},"

         ."${SSB1_SSOMGR},${SSB2_SSOMGR},${SSB3_SSOMGR},${SSB4_SSOMGR},"
         ."${SSB1_SSOMGR_CW},${SSB2_SSOMGR_CW},${SSB3_SSOMGR_CW},${SSB4_SSOMGR_CW},"

         ."${loadAvg1},${loadAvg5},${loadAvg15},"
         ."${RequestsPerSec},${RequestsInProc},${IdleWorkers}"
         ."\n";

#print $FileDataLine ;
#print  $fhoutfile $FileDataLine ;


close ( $fhoutfile );

# Nagios Sending data items.....


my $NagiosMessage = "" 
        ."${ServerIPv4}\tApache_80\t0\t${Apache80} Current Connections|procs=${Apache80};10;25;0\n"
        ."${ServerIPv4}\tApache_443\t0\t${Apache443} Current Connections|procs=${Apache443};10;25;0\n"
        ."${ServerIPv4}\tApache_10443\t0\t${Apache10443} Current Connections|procs=${Apache10443};10;25;0\n"
        ."${ServerIPv4}\tApache_20443\t0\t${Apache20443} Current Connections|procs=${Apache20443};10;25;0\n"

        ."${ServerIPv4}\tApache_80_TW\t0\t${Apache80_TW} Lingering Connections|procs=${Apache80_TW};10;25;0\n"
        ."${ServerIPv4}\tApache_443_TW\t0\t${Apache443_TW} Lingering Connections|procs=${Apache443_TW};10;25;0\n"
        ."${ServerIPv4}\tApache_20443_TW\t0\t${Apache20443_TW} Lingering Connections|procs=${Apache20443_TW};10;25;0\n"
        ."${ServerIPv4}\tApache_10443_TW\t0\t${Apache10443_TW} Lingering Connections|procs=${Apache10443_TW};10;25;0\n"

        ."${ServerIPv4}\tSSB1_OHS_${OHSPort}\t0\t${SSB1_OHS} Current Connections|procs=${SSB1_OHS};10;25;0\n"
        ."${ServerIPv4}\tSSB2_OHS_${OHSPort}\t0\t${SSB2_OHS} Current Connections|procs=${SSB2_OHS};10;25;0\n"
        ."${ServerIPv4}\tSSB3_OHS_${OHSPort}\t0\t${SSB3_OHS} Current Connections|procs=${SSB3_OHS};10;25;0\n"
        ."${ServerIPv4}\tSSB4_OHS_${OHSPort}\t0\t${SSB4_OHS} Current Connections|procs=${SSB4_OHS};10;25;0\n"

        ."${ServerIPv4}\tSSB1_OHS_${OHSPort}_CW\t0\t${SSB1_OHS_CW} Lingering Connections|procs=${SSB1_OHS_CW};10;25;0\n"
        ."${ServerIPv4}\tSSB2_OHS_${OHSPort}_CW\t0\t${SSB2_OHS_CW} Lingering Connections|procs=${SSB2_OHS_CW};10;25;0\n"
        ."${ServerIPv4}\tSSB3_OHS_${OHSPort}_CW\t0\t${SSB3_OHS_CW} Lingering Connections|procs=${SSB3_OHS_CW};10;25;0\n"
        ."${ServerIPv4}\tSSB4_OHS_${OHSPort}_CW\t0\t${SSB4_OHS_CW} Lingering Connections|procs=${SSB4_OHS_CW};10;25;0\n"

        ."${ServerIPv4}\tSSB1_CASCADE_${CascadePort}\t0\t${SSB1_CASCADE} Current Connections|procs=${SSB1_CASCADE};10;25;0\n"
        ."${ServerIPv4}\tSSB2_CASCADE_${CascadePort}\t0\t${SSB2_CASCADE} Current Connections|procs=${SSB2_CASCADE};10;25;0\n"
        ."${ServerIPv4}\tSSB3_CASCADE_${CascadePort}\t0\t${SSB3_CASCADE} Current Connections|procs=${SSB3_CASCADE};10;25;0\n"
        ."${ServerIPv4}\tSSB4_CASCADE_${CascadePort}\t0\t${SSB4_CASCADE} Current Connections|procs=${SSB4_CASCADE};10;25;0\n"

        ."${ServerIPv4}\tSSB1_CASCADE_${CascadePort}_CW\t0\t${SSB1_CASCADE_CW} Lingering Connections|procs=${SSB1_CASCADE_CW};10;25;0\n"
        ."${ServerIPv4}\tSSB2_CASCADE_${CascadePort}_CW\t0\t${SSB2_CASCADE_CW} Lingering Connections|procs=${SSB2_CASCADE_CW};10;25;0\n"
        ."${ServerIPv4}\tSSB3_CASCADE_${CascadePort}_CW\t0\t${SSB3_CASCADE_CW} Lingering Connections|procs=${SSB3_CASCADE_CW};10;25;0\n"
        ."${ServerIPv4}\tSSB4_CASACDE_${CascadePort}_CW\t0\t${SSB4_CASCADE_CW} Lingering Connections|procs=${SSB4_CASCADE_CW};10;25;0\n"

        ."${ServerIPv4}\tSSB1_SSOMGR_${SSOMGRPort}\t0\t${SSB1_SSOMGR} Current Connections|procs=${SSB1_SSOMGR};10;25;0\n"
        ."${ServerIPv4}\tSSB2_SSOMGR_${SSOMGRPort}\t0\t${SSB2_SSOMGR} Current Connections|procs=${SSB2_SSOMGR};10;25;0\n"
        ."${ServerIPv4}\tSSB3_SSOMGR_${SSOMGRPort}\t0\t${SSB3_SSOMGR} Current Connections|procs=${SSB3_SSOMGR};10;25;0\n"
        ."${ServerIPv4}\tSSB4_SSOMGR_${SSOMGRPort}\t0\t${SSB4_SSOMGR} Current Connections|procs=${SSB4_SSOMGR};10;25;0\n"

        ."${ServerIPv4}\tSSB1_SSOMGR_${SSOMGRPort}_CW\t0\t${SSB1_SSOMGR_CW} Lingering Connections|procs=${SSB1_SSOMGR_CW};10;25;0\n"
        ."${ServerIPv4}\tSSB2_SSOMGR_${SSOMGRPort}_CW\t0\t${SSB2_SSOMGR_CW} Lingering Connections|procs=${SSB2_SSOMGR_CW};10;25;0\n"
        ."${ServerIPv4}\tSSB3_SSOMGR_${SSOMGRPort}_CW\t0\t${SSB3_SSOMGR_CW} Lingering Connections|procs=${SSB3_SSOMGR_CW};10;25;0\n"
        ."${ServerIPv4}\tSSB4_SSOMGR_${SSOMGRPort}_CW\t0\t${SSB4_SSOMGR_CW} Lingering Connections|procs=${SSB4_SSOMGR_CW};10;25;0\n"

        ."${ServerIPv4}\tLoadAverage1\t0\t${loadAvg1} Load 1 minute average|procs=${loadAvg1};10;25;0\n"
        ."${ServerIPv4}\tLoadAverage5\t0\t${loadAvg5} Load 5 minute average|procs=${loadAvg5};10;25;0\n"
        ."${ServerIPv4}\tLoadAverage15\t0\t${loadAvg15} Load 15 minute average|procs=${loadAvg15};10;25;0\n"

        ."${ServerIPv4}\tRequestsPerSec\t0\t${RequestsPerSec} Current Requests per Second|procs=${RequestsPerSec};10;25;0\n"
        ."${ServerIPv4}\tRequestsInProc\t0\t${RequestsInProc} Requests being processed|procs=${RequestsInProc};10;25;0\n"
        ."${ServerIPv4}\tIdleWorker\t0\t${IdleWorkers} Idle Workers|procs=${IdleWorkers};10;25;0\n"

        ;
#print $NagiosMessage;


print $FileDataLine ;


#  Subroutines are below

use MIME::Base64;
use Digest::SHA1 qw(sha1 sha1_hex sha1_base64);

sub post_data
{
  my ($p_data) = {"data"=> @_};
  my $ua = LWP::UserAgent->new;
  my $server_address = "https://graphiteserver.example.com/graphite/data/shim";
  my $request = HTTP::Request->new( POST => $server_address);
  my $response = $ua->post( $server_address, $p_data );
  if($response->is_success)
  {
    my $message = $response->decoded_content();
    print "Reply: $message\n";
  }
  else
  {
    print "HTTP Post Error Code: ", $response->code, "\n";
    print "HTTP Post Error Message: ", $response->message, "\n";
  }
}

sub generate_random_string
{ 
  my $length_of_randomstring=shift;  # the length of the random string to generate
  my @chars=('a'..'z','A'..'Z','0'..'9','_'); my $random_string;
  foreach (1..$length_of_randomstring) 
    { # rand @chars will generate a random number between 0 and scalar @chars
      $random_string.=$chars[rand @chars];
    } return $random_string;
}

sub trim($)
{ my $string = shift; $string =~ s/^\s+//; $string =~ s/\s+$//; return $string; }
 
# Left trim function to remove leading whitespace
sub ltrim($)
{ my $string = shift; $string =~ s/^\s+//; return $string; }

# Right trim function to remove trailing whitespace
sub rtrim($)
{ my $string = shift; $string =~ s/\s+$//; return $string; }

sub ascii_to_hex ($)
{ (my $str = shift) =~ s/(.|\n)/sprintf("%02lx", ord $1)/eg; return $str; }

sub hex_to_ascii ($)
{ (my $str = shift) =~ s/([a-fA-F0-9]{2})/chr(hex $1)/eg; return $str; }


