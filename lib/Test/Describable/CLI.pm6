use Test::Describable::Containers;
proto MAIN(|) is export {
    {*}
}
multi MAIN(:$DEBUG! where $DEBUG == True, |) {
    my @*tests;
    my $result = $first-level-descrs.run: :$DEBUG;
    say report $result, :$DEBUG
}
multi MAIN(|) {
    my @*tests;
    say report $first-level-descrs.run
}

multi MAIN("list") {
    say $first-level-descrs.list
}

multi MAIN("lines") {
    for %per-line.keys.sort -> $k {
        say "$k  => {%per-line{$k}.^name}"
    }
}

multi MAIN("run", UInt() $line) {
    my @*tests;
    say report %per-line{+$line}.run
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
            #.note with $test<error>;
            my $error = S:g/^^/# / with $test<error> and $test<error>.?gist;
            |(
                $res || Empty,
                "{$test<response> ?? "ok" !! "not ok"} {$id++} - {$test<name> // ""}",
                ($error || Empty)
            )
        },
    ).join: "\n"
}
