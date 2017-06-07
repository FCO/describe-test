my $lock = Lock.new;
sub pass($name) is export {
    $lock.protect: {
        die "It should be used inside of a 'it'" without @*TESTS;
        @*TESTS.push: {:response, :$name}
    }
}

sub didn't-pass($name, $comment?) is export {
    $lock.protect: {
        die "It should be used inside of a 'it'" without @*TESTS;
        @*TESTS.push: {:!response, :$name, :$comment}
    }
}

sub error($name, $error) is export {
    $lock.protect: {
        die "It should be used inside of a 'it'" without @*TESTS;
        @*TESTS.push: {:$name, :!response, :$error}
    }
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

