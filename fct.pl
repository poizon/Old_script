#!/usr/bin/perl -w
#
$|=1;
use strict;
use warnings;
use lib qw(.);
use Libs::Common;
use Libs::FCT;
use Libs::DB;
use CGI::Simple;
############################
## Глобальные переменные
# Для TomCat'a устанавливаем окружение
$ENV{"SYSTEMROOT"} = "C:\\windows";
$CGI::Simple::PARAM_UTF8 = 1;
# Читаем конфигурацию
my $c = Libs::Common->new();
my %config = $c->read_config();
# Объект CGI-Simple
my $q = CGI::Simple->new();
my $fct = Libs::FCT->new();
# парсим входящие параметры в хэш
my %in = $q->Vars();
my $output = 0;
my $method = _clean($in{act});
# коннект к БД
my $db = Libs::DB->connect(
        hostname => $config{hostname},
        database => $config{database},
        user     => $config{user},
        password => $config{password},
    );

# проверяем сессию и пользователя
#my $check = $c->user_check($db, \%in);
# если проверка непрошла - то ставим output в 1, чтобы сгенерировать ошибку
#$output = 1 unless $check;

if($fct->can($method) && !$output) {
    eval {
            $output = $fct->$method($db, \%in, \%config);
        };
    
    if($@) {
        $output = $fct->catch_error($@,\%config);
        print STDERR $output;
    }
    
}
else {
    $output = 'Системная ошибка!';
}

print $q->header(-charset => 'utf-8');
print $output,"\n";


######################################################
## ITERNAL SUBS

# здесь чистим входящие данные.
# пока к очистке только параметр act
sub _clean {
my $method = shift || 'act';
$method =~ s/[^a-z_0-9]+//g;
$method =~ s/new//g;
return $method;
}