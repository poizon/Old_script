use common::sense;
use DDP;

my $A = fill_array();
my $B = fill_array();

my $show = SFDraw->new();
$show->main_window($A, $B);


say "q - quit, s - auto set ships";

my $user_input = <STDIN>;
chomp($user_input);
exit if $user_input eq "q";

init_ships($A, $B) if $user_input eq "s";

$show->main_window($A, $B);

sub fill_array
{
  my @emtry_space;

  for (my $i=0;$i<10;$i++)
  {
    for (my $j=0;$j<10;$j++)
    {
      $emtry_space[$i][$j] = 0;
    }

  }

  return \@emtry_space;
}

sub init_ships
{
  my ( $A, $B) = @_;

}

package SFDraw;

sub new
{
  my $self = shift;
  bless( {}, $self );
}

sub main_window
{
  my ( $this, $A, $B ) = @_;

  if($^O eq 'MSWin32')
  {
    system("cls");
  }
  elsif($^O eq 'Linux')
  {
    system("clear");
  }

  draw_logo();

  draw_line();
  draw_tab(1);
  draw_line();
  say;
  draw_words();
  draw_tab(2);
  draw_words();
  say;
  draw_line();
  draw_tab(1);
  draw_line();
  say;
  show_fields($A, $B);
  say;
}

sub draw_logo
{
  draw_tab(2);
  say "="x22;
  draw_tab(2);
  say "===== SEA FIGHT! =====";
  draw_tab(2);
  say "="x22;

}

sub draw_tab
{
  my $t = shift;
  print "\t"x$t;
}

sub draw_line
{
  print "- "x12;
}

sub draw_words
{
  print uc("  | a b c d e f g h i j");
}

sub show_fields
{
  my $fieldA = shift;
  my $fieldB = shift;
  for (my $i=0;$i<10;$i++)
  {
    print $i . " | ";

    for (my $j=0;$j<10;$j++)
    {
      print $fieldA->[$i]->[$j] . " ";
    }

    draw_tab(1);

    print $i . " | ";
    for (my $j=0;$j<10;$j++)
    {
      print $fieldB->[$i]->[$j] . " ";
    }
    print "\n";
  }
}

1;
