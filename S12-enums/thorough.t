use v6;

use Test;

plan 71;

=begin description

Enum tests from L<S12/Enums>

=end description

#?pugs 999 skip
# L<S12/Enums/values are specified as a list>
enum day <Sun Mon Tue Wed Thu Fri Sat>;

ok day ne "", 'enum itself stringififes';
#?rakudo skip 'regression'
ok day.WHAT, 'enum.WHAT returned a value';
ok day.perl, 'enum.perl returned a value';

sub test_stuff($x) {
#?rakudo 1 skip '.does for enum value - XXX is this really valid test? asked TimToady...'
  ok $x.does(day::Tue),    "basic enum mixing worked ($x-2)";
  is $x.day, 2,            "automatically created accessor worked ($x)";
  is day::Tue, 2,          "enum provided a correct mapping ($x)";
  ok $x ~~ day,            "smartmatch worked correctly ($x-1)";
  ok $x ~~ Tue,            "smartmatch worked correctly ($x-2)";
  ok $x ~~ day::Tue,       "smartmatch worked correctly ($x-3)";
  ok $x !~~  Wed,          "smartmatch worked correctly ($x-4)";
#?rakudo 1 skip '.does for enum value - XXX is this really valid test? asked TimToady...'
  ok $x.does(Tue),         ".does worked correctly ($x-1)";
  ok $x.does(day),         ".does worked correctly ($x-2)";
  #?rakudo skip 'EnumValue($x)'
  ok Tue($x),              "Tue() worked correctly ($x)";
  ok $x.Tue,               ".Tue() worked correctly ($x)";
  #?rakudo skip 'unknown bug'
  ok $x.Tue.WHAT,          '$obj.Tue.WHAT returns a true valuee';
  ok $x.Tue.perl,          '$obj.Tue.perl returns a true valuee';
}

{
  my $x = 1;
  is $x, 1, "basic sanity (1)";
  # L<S12/Enums/has the right semantics mixed in:>
  ok $x does day(Tue), "basic enum mixing worked (1-1)";
  test_stuff($x);
}

#?DOES 15
#?rakudo skip 'does day<tue> - but is this even valid?'
{
  my $x = 2;
  is $x, 2, "basic sanity (2)";
  # L<S12/Enums/or pseudo-hash form:>
  ok $x does day<Tue>, "basic enum mixing worked (2-1)";
  test_stuff($x);
}

#?rakudo skip 'does day::Tue'
{
  my $x = 3;
  is $x, 3, "basic sanity (3)";
  # L<S12/Enums/is the same as>
  ok $x does day::Tue, "basic enum mixing worked (3-1)";
  test_stuff($x);
}

#?DOES 16
#?rakudo skip 'does &day::("Tue")'
{
  my $x = 4;
  is $x, 4, "basic sanity (4)";
  # L<S12/Enums/which is short for something like:>
  ok $x does day,            "basic enum mixing worked (4-0)";
  ok $x.day = &day::("Tue"), "basic enum mixing worked (4-1)";
  test_stuff($x);
}

# used to be Rakudo regression, RT #64098
#?rakudo skip 'augment'
#?DOES 2
{
    augment class Object {
        method f { 'inObject' };
    }

    augment class Bool {
        method f { 'inBool' };
    }
    is True.f, 'inBool', 'method on short name pick up the one from the enum';
    is Bool::True.f, 'inBool', 'method on long name pick up the one from the enum';
}

ok True.perl ~~/^ 'Bool::True'/, 'True.perl';
ok Bool::True.perl ~~/^ 'Bool::True'/, 'Bool::True.perl';

{
    enum Negation << :isnt<isnt> :arent<arent> :amnot<amnot> :aint<aint> >>;
    my Negation $foo;
    #?rakudo todo 'Null PMC Access in invoke()'
    lives_ok { $foo = Negation::isnt }, 'simple assignment from enum';
    #?rakudo skip 'Null PMC Access in invoke()'
    is $foo, Negation::isnt, 'assignment from enum works';
}

# RT #66886
{
    enum RT66886 <b>;
    #?rakudo todo 'RT #66886'
    eval_dies_ok 'RT66886::c', 'accessing non-value of enum dies proper-like';
}

# vim: ft=perl6
