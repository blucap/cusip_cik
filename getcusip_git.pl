#!/usr/bin/perl -w
use LWP;
use strict;
use HTML::Restrict;
use HTML::Strip;
#my $hr = HTML::Restrict->new();
my $hs = HTML::Strip->new();

my $prefix='https://www.sec.gov/Archives/edgar/data';
            
# user agent object for handling HTTP requests
my $ua = LWP::UserAgent->new;
#$ua->proxy(['http', 'ftp'], 'http://wwwcache.lancs.ac.uk:8080/');

# list of values to search for in the report:
#                 tag      pattern
#                 ---      -------
my @fields = ( [ "NAM", "COMPANY CONFORMED NAME:" ],	
               [ "CIK", "CENTRAL INDEX KEY:" ],
               [ "PER", "CONFORMED PERIOD OF REPORT:" ],
               [ "FD",  "FILED AS OF DATE:" ],
               [ "CIT", "CITY:" ],
               [ "STT", "STATE:" ]);#,
               #[ "FYR", "FISCAL YEAR END:" ],
               #[ "SIC", "STANDARD INDUSTRIAL CLASSIFICATION:" ]);
my $z;
my $countlines;
my $result;
               
for ($z=2017; $z>=1993; $z--)
{
    my $infile="cobs$z.txt";
    my $outfile="igout$z.txt";
    
    $countlines = `wc -l < $infile`;
    die "wc failed: $?" if $?;
    $countlines = $countlines + 0;
    if ($countlines > 0)
    {
        print "Rows in file: $countlines\n";
    }
    
    my $begin=time();
    open(OUT, ">$outfile") or die;

    # read the list of files to fetch
    open(IN, $infile) or die;
    my @mainsic = <IN>;
    close IN;

    my $count = 0;
    my $teller = 0;
    for my $entry (@mainsic)
    {
        # trim any spaces on the entry
        $entry=~ s/^\s*//;
        $entry=~ s/\s*$//;

        # fetch the file
        my $page = get_http($prefix.$entry);
        # my $page = get_http('https://www.sec.gov/Archives/edgar/data/316709/0000215457-17-002210.txt');
        next if (!defined $page);
        $teller++;
        printf "read $teller '%s' got %d bytes\n", $prefix.$entry, length($page);
        #my $page = $hr->process( $page );
        my $page = $hs->parse( $page );
        
    last if ($count++ > $countlines);
    last if ($count++ > 5);

        my $output_line = $prefix.$entry;
        for (@fields)
        {
            my ($key, $pattern) = @$_;
            my $result;

            if ($page =~ /$pattern(.*)/)
            {
                $result = $1;
                $result=~ s/^\s*//;
                $result=~ s/\s*$//;
                $result=~ s/\,//g; # Substitute all commas with nothing
                #$result=~ tr/ //s;
                #$result=~ s/\h+/ /g;
            }
            else
            {
                $result = "leeg";
            }
            $output_line .= ",$key,$result";
        }
	if ($page =~ /CUSIP(?:\s+(?:No\.|#|Number):?)?\s+([0-9A-Z]{1,3}[\s-]?[0-9A-Z]{3}[\s-]?[0-9A-Z]{2}[\s-]?\d{1})/i)
	{
	    $result = $1;
	    $result=~ s/^\s*//;
	    $result=~ s/\s*$//;
	}
	else #{$result = "No_Cusip";}
	{
	    if ($page =~ /CUSIP\:\s+([0-9A-Z]{1,3}[\s-]?[0-9A-Z]{3}[\s-]?[0-9A-Z]{2}[\s-]?\d{1})/i)
	    {
	      $result = $1;
	      $result=~ s/^\s*//;
	      $result=~ s/\s*$//;
	    }
	    else
	    {
	      $result = "No_Cusip";
	    }
	}
	$output_line .= ",Cusyp,$result";  
        $output_line .= ";\n";
        print OUT $output_line;
        print $output_line;
        
    }
    my $einde=time();
    my $lapsed=$einde-$begin;
    #print OUT "Einde: $einde Begin: $begin Verschil: $lapsed;\n";
    print "Einde: $einde Begin: $begin Verschil: $lapsed\n";
    close OUT;
}

sub get_http
{
    my $url = shift;

    my $request = HTTP::Request->new(GET => $url);
    my $response = $ua->request($request);
    if (!$response->is_success)
    {
        print STDERR "GET '%s' failed: %s\n",
            $url, $response->status_line;
        return undef;
    }
    return $response->content;
}
