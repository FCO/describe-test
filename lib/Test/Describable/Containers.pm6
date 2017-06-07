use Test::Describable::Describe;
our $first-level-descrs is export = Describe.new: :name<MAIN>;
our %per-line is export;


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

multi before(%data) is export {
    samewith -> *%data {%data}.assuming: |%data
}

multi before(&code) is export {
    die "'before' must be used inside of a 'describe'" without @*BEFORE;
    @*BEFORE.push: &code
}

multi before-each(%data) is export {
    samewith -> *%data {%data}.assuming: |%data
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

