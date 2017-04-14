#!/usr/bin/perl -w
#
use common::sense;
use Mojo::UserAgent;
use XML::Parser;
use DBI;
use DBD::ODBC;
use Date::Simple qw(today);
#############################################
my $VERSION = 1.3;
my %setup = parse_config();
my $date = today();
my $sql_date = $date->format("%Y-%d-%m");
my @currency = qw(USD EUR CHF);
my %hash = ();
my $prev_elem = undef;
my $url = sprintf("http://www.cbr.ru/scripts/XML_daily.asp?date_req=%s",$date->format("%d/%m/%Y"));
my $counter = 0; # ограничение на рекурсию
##############################################
my $xml = get_curses($url);

my $p2 = XML::Parser->new(Handlers => {
                                        Char  => \&chrhndl,
                                       });

$p2->parse($xml);

# логи в файл
logs("USD: $hash{USD}\nEUR: $hash{EUR}\nCHF: $hash{CHF}");
#SELECT T0.RateDate, T0.Currency, T0.Rate FROM ORTT T0 WHERE T0.RateDate =N'2007-01-07'
###
foreach my $kk(split (/,/,$setup{db})) {# начала прохода по списку БД
  my $DSN="driver={SQL Server};Server=$setup{server};database=$kk;uid=$setup{user};pwd=$setup{pass}";
  # подключаемся к конкретной БД
  my $dbh = DBI->connect("dbi:ODBC:$DSN", { PrintError=>1,RaiseError => 1}) or die "$DBI::errstr\n";
  $dbh->{AutoCommit} = 0;# выключаем автокоммит

  foreach my $key(keys %hash) {
    # если ключа нет в массиве валют - пропускаем
    next unless $key ~~ @currency;
    
    $hash{$key} =~ s/,/./;
    my $sql = qq(INSERT INTO ORTT VALUES('$sql_date',N'$key',$hash{$key},'I',13));
    say $sql;
    my $sth = $dbh->do($sql);
    
    if($sth)
    {
      $dbh->commit;# коммитим
    }
    else
    {
      $dbh->rollback;# откатываем
      logs("Error at $date: $sql\n$DBI::errstr\n");
    }
    
  }
  
  $dbh->disconnect;
}

exit;

##############################################
sub get_curses
{
  my $url = shift;
  my $ua = Mojo::UserAgent->new;
  $ua->connect_timeout(10);
  $ua->inactivity_timeout(25);
  $ua->max_redirects(4);
  $ua->request_timeout(15);

  my $tx = $ua->get($url);

  if( $tx->res->code eq '200')
  {
    return $tx->res->body;
  }
  else {
    logs($tx->res->code);
    sleep(15); # приуснем немного и повторим
    $counter++;
    exit 0 if $counter > 5;# если слишком много неудачных
    return get_curses($url);
  }

}

sub chrhndl {
  my ($xp, $data) = @_;

  if($xp->current_element eq 'CharCode')
  {
    $prev_elem = $data;
  }
  elsif ($xp->current_element eq 'Value')
  {
    #say $prev_elem . ":" . $data if DEBUG;
    $hash{$prev_elem} = $data;
  }

}

sub logs
{
  my $msg = shift;
  open(DEBUG,">>","curs.txt") || die "can't create file: $!\n";
  say DEBUG $date->format("%d/%m/%Y");
  say DEBUG $msg;
  say DEBUG "="x20;
  close(DEBUG);
}

# парсим конфигурационный файл config.dat
sub parse_config
{
  my %CONFIG;
  open(CFG,"<","./config.dat") || die "Config not found: $!\n";
  while(<CFG>) {
    next if(/^\#/);
    chomp;
    my($key,$value) = split(/=/,$_);
    $CONFIG{$key} = $value if(defined($key) && defined($value));
  }
  
  return %CONFIG;
}
