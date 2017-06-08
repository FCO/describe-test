use Test::Describable::Containers;
use Test::Describable::Describe;
proto MAIN(|) is export {
    {*}
}
multi MAIN(Bool :$DEBUG! where $DEBUG == True) {
    my @*tests;
    my $result = $first-level-descrs.run: :$DEBUG;
    say report $result, :$DEBUG
}
multi MAIN() {
    my @*tests;
    say report $first-level-descrs.run
}

multi MAIN("list") {
    say $first-level-descrs.list
}

multi MAIN("lines") {
    say %per-line.keys.sort(+*).join: ", "
}

multi MAIN("run", *@lines) {
    my @*tests;
    my $desc;
    if @lines > 1 {
        my %descrs = %per-line{@lines.map: +*}:kv;
        $desc = Describe.new(:%descrs)
    } else {
        $desc = %per-line{+@lines.first}
    }
    say report $desc.run
}

sub report(@tests, :$DEBUG) {
    my $id = 1;
    (
        "1..{@tests.elems}",
        |do for @tests -> $test {
            my $res = "";
            if $test<describe>:exists {
                $res = "{report($test<describe>)}".indent: 5;
            }
            my $error = S:g/^^/# / with $test<error> and $test<error>.?gist;
            |(
                $res || Empty,
                "{$test<response> ?? "ok" !! "not ok"} {$id++} - {$test<name> // ""}",
                ($error || Empty)
            )
        },
    ).join: "\n"
}
