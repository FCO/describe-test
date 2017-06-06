my %per-line{UInt};
class Describe {
    has Str      $.name;
    has Callable %.its;
    has Describe %.descrs;
    has Callable @.before;
    has Callable @.before-each;
    has Callable @.after;
    has Callable @.after-each;
    has UInt     $.line;

    method debug($msg, :$DEBUG)     {note $msg if $DEBUG}
    method size {
        %!descrs + %!its
    }
    method list {
        (
            |do for %!descrs.kv -> $name, $d {
                (
                    "$name => {$d.line}",
                    $d.list.indent(5),
                ).join: "\n"
            },
            |do for %!its.kv -> $name, &it {
                "$name => {&it.line}"
            }
        ).join: "\n"
    }
    multi method run(Bool :$DEBUG, Set :$run = Set.new) is hidden-from-backtrace {
        my @tests;
        for keys @!before (-) $run -> &exec-before {
            $.debug("before", :$DEBUG);
            my $res = exec-before;
            await $res if $res ~~ Promise;
        }
        await |do for %!descrs.values -> $d {
            start {
                $.debug("describe {$d.name}", :$DEBUG);
                my @responses = $d.run(:$DEBUG, :run(@!before ∪ @!after ∪ $run));
                my $res = [&&] @responses.map: *<response>;
                @tests.push: {
                    :name($d.name),
                    size        => $d.size,
                    response    => $res,
                    describe    => @responses,
                };
            }
        },
        |do for %!its.kv -> $name, &it {
            start {
                for @!before-each -> &exec-before-each {
                    $.debug("before each...", :$DEBUG);
                    exec-before-each
                }
                $.debug("running it", :$DEBUG);
                my @*TESTS;
                my $ret = it;
                if $ret ~~ Promise {
                    await $ret;
                }

                @tests.append: @*TESTS;
                for @!after-each -> &exec-after-each {
                    $.debug("after each...", :$DEBUG);
                    exec-after-each
                }
                CATCH {
                    default {
                        error $name, $_;
                        .resume
                    }
                }
            }
        }

        for keys @!after (-) $run -> &exec-after {
            $.debug("after", :$DEBUG);
            my $res = exec-after;
            await $res if $res ~~ Promise;
        }
        @tests
    }
}

our $first-level-descrs = Describe.new: :name<MAIN>;

proto describe(|) is export is hidden-from-backtrace {{*}}
multi describe((:$key, :&value)) is hidden-from-backtrace {
    samewith $key, &value
}
multi describe(Str $name is copy, &code) is hidden-from-backtrace {
    $name //= "NO NAME DESCRIBE {++$}";
    my %descrs;
    my %its;
    my @before      = @*BEFORE       with @*BEFORE;
    my @before-each = @*BEFORE-EACH  with @*BEFORE-EACH;
    my @after       = @*AFTER        with @*AFTER;
    my @after-each  = @*AFTER-EACH   with @*AFTER-EACH;
    {
        my %*DESCRS;
        my %*ITS;
        my @*BEFORE      = @before;
        my @*BEFORE-EACH = @before-each;
        my @*AFTER       = @after;
        my @*AFTER-EACH  = @after-each;

        code;
        %descrs      = %*DESCRS;
        %its         = %*ITS;
        @before      = @*BEFORE;
        @before-each = @*BEFORE-EACH;
        @after       = @*AFTER;
        @after-each  = @*AFTER-EACH;
    }
    my $obj = Describe.new:
        :$name,
        :%descrs,
        :%its,
        :@before,
        :@before-each,
        :@after,
        :@after-each,
        :line(&code.line)
    ;

    with %*DESCRS {
        %*DESCRS.push: $obj.name => $obj;
    } else {
        $first-level-descrs.descrs.push: $obj.name => $obj
    }
    %per-line{&code.line} = $obj;
}

proto it(|) is export is hidden-from-backtrace {{*}}
multi it(&code) is hidden-from-backtrace {
    samewith "It {++$}", &code
}
multi it(Pair (:$key, :&value)) is hidden-from-backtrace {
    samewith $key, &value
}
multi it(Str $name is copy, &code) is hidden-from-backtrace {
    die "'it' must be used inside of a 'describe'" without %*ITS;
    $name //= "NO NAME IT {++$}";
    %per-line{&code.line} //= Describe.new;
    %per-line{&code.line}.its.push: $name => &code;
    %*ITS.push: $name => &code;
}

multi before(&code) is export {
    die "'before' must be used inside of a 'describe'" without @*BEFORE;
    @*BEFORE.push: &code
}

multi before-each(&code) is export {
    die "'before-each' must be used inside of a 'describe'" without @*BEFORE-EACH;
    @*BEFORE-EACH.push: &code
}

multi after(&code) is export {
    die "'after' must be used inside of a 'describe'" without @*AFTER;
    @*AFTER.push: &code
}

multi after-each(&code) is export {
    die "'after-each' must be used inside of a 'describe'" without @*AFTER-EACH;
    @*AFTER-EACH.push: &code
}

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

sub pass($name) is export {
    die "It should be used inside of a 'it'" without @*TESTS;
    @*TESTS.push: {:response, :$name}
}

sub didn't-pass($name, $comment?) is export {
    die "It should be used inside of a 'it'" without @*TESTS;
    @*TESTS.push: {:!response, :$name, :$comment}
}

sub error($name, $error) is export {
    die "It should be used inside of a 'it'" without @*TESTS;
    @*TESTS.push: {:$name, :!response, :$error}
}

sub ok($v, $name?) is export {
    if $v {
        pass $name
    } else {
        didn't-pass $name
    }
}

sub is($v1, $v2, $name?) is export {
    ok $v1 ~~ $v2, $name
}
