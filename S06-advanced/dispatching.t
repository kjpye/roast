use v6;
use Test;
use soft;
plan 13;
my @order;

my class C1 {
    method foo(|) { @order.push: ::?CLASS.^name }
}

my class C2  is C1 {
    proto method foo(|) {*}
    multi method foo(Str $s) {
        @order.push: ::?CLASS.^name ~ "(Str)";
        nextsame;
    }
    multi method foo(Int $s) {
        @order.push: ::?CLASS.^name ~ "(Int)";
        nextsame;
    }
    multi method foo(Num) {
        @order.push: ::?CLASS.^name ~ "(Num)";
        nextsame
    }
}

my class C3 is C2 {
    method foo(|) {
        @order.push: ::?CLASS.^name;
        nextsame
    }
}

my class C4 is C3 {
    proto method foo(|) {*}
    multi method foo(Int:D $v) {
        @order.push: ::?CLASS.^name ~ "(Int:D)";
        nextwith ~$v
    }
    multi method foo(Any) {
        @order.push: ::?CLASS.^name ~ "(Any)";
        callsame
    }
}

my $inst;

$inst = C3.new;
$inst.foo("bar");
is-deeply @order.List, <C3 C2(Str) C1>, "a multi-method doesn't break MRO dispatching";
@order = [];
$inst.foo(42);
is-deeply @order.List, <C3 C2(Int) C1>, "a multi-method dispatching works correctly";

$inst = C4.new;
@order = [];
$inst.foo("baz");
is-deeply @order.List, <C4(Any) C3 C2(Str) C1>, "multi being the first method in MRO still works";
@order = [];
$inst.foo(13);
is-deeply @order.List, <C4(Int:D) C4(Any) C3 C2(Str) C1>, "nextwith does what's expected";

my \proto := C2.^find_method('foo', :local, :no_fallback);

nok proto.is_wrapped, "proto is not wrapped yet";
my $wh1 = proto.wrap(my method foo-wrap(|) { @order.push: "foo-proto"; nextsame });
ok proto.is_wrapped, "proto is wrapped now";

@order = [];
$inst.foo("");
is-deeply @order.List, <C4(Any) C3 foo-proto C2(Str) C1>, "proto can be wrapped";

proto.unwrap($wh1);
@order = [];
$inst.foo("");
is-deeply @order.List, <C4(Any) C3 C2(Str) C1>, "proto can be unwrapped";

# This should be foo(Rat) candidate
my \cand = proto.candidates[2];
# Note that next* can't be used with blocks.
$wh1 = cand.wrap(-> *@ { @order.push('foo-num-wrap'); callsame });
@order = [];
$inst.foo(pi);
is-deeply @order.List, <C4(Any) C3 foo-num-wrap C2(Num) C1>, "we can wrap a candidate";

# We can even wrap a candidate with another multi. It works!
proto multi-wrap(|) {*}
multi multi-wrap(\SELF, Num) {
    @order.push: "multi-wrap(Num)";
    nextsame
}
multi multi-wrap(\SELF, Any) {
    @order.push: "multi-wrap(Any)";
    nextsame
}

my $wh2 = cand.wrap(&multi-wrap);
@order = [];
$inst.foo(pi);
is-deeply @order.List, <C4(Any) C3 multi-wrap(Num) multi-wrap(Any) foo-num-wrap C2(Num) C1>, "we can use a multi as a wrapper of a candidate";

cand.unwrap($wh1);
@order = [];
$inst.foo(pi);
is-deeply @order.List, <C4(Any) C3 multi-wrap(Num) multi-wrap(Any) C2(Num) C1>, "we can use a multi as a wrapper of a candidate";

# Even nastier thing: wrap a candidate of our wrapper!
my $wwh = &multi-wrap.candidates[1].wrap(sub (|) { @order.push: 'cand-wrap'; nextsame });
@order = [];
$inst.foo(pi);
is-deeply @order.List, <C4(Any) C3 multi-wrap(Num) cand-wrap multi-wrap(Any) C2(Num) C1>, "we can use a multi as a wrapper of a candidate";

# Unwrap the method candidate from the second wrapper. We then get the original behavior.
cand.unwrap($wh2);
@order = [];
$inst.foo(pi);
is-deeply @order.List, <C4(Any) C3  C2(Num) C1>, "we can use a multi as a wrapper of a candidate";

done-testing;