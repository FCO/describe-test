use Test::Describable::Funcs;
sub run-sub-with-data(&code, %data) {
    my @keys = &code
        .signature
        .params
        .grep(*.named)
        .map: *.name.substr: 1
    ;
    my %pairs = @keys Z=> %data{|@keys};
    my $res;
    if %pairs {
        $res = code |%pairs
    } else {
        $res = code $%pairs
    }
    $res = await $res if $res ~~ Promise;
    %data ,= |$res if $res ~~ Associative
}

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
                    "$name: #{$d.line}",
                    $d.list.indent(5),
                ).join: "\n"
            },
            |do for %!its.kv -> $name, &it {
                "$name #{&it.line}"
            }
        ).join: "\n"
    }
    multi method run(Bool :$DEBUG, Set :$run = Set.new, :%data) {
        my @tests;
        for keys @!before (-) $run -> &exec-before {
            $.debug("before", :$DEBUG);
            %data ,= |run-sub-with-data &exec-before, %data
        }
        my @proms = |do for %!descrs.values -> $d {
            start {
                $.debug("describe {$d.name}", :$DEBUG);
                my @responses = $d.run(:$DEBUG, :run(@!before ∪ @!after ∪ $run), :%data);
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
                    %data ,= |run-sub-with-data &exec-before-each, %data
                }
                $.debug("running it", :$DEBUG);
                my @*TESTS;
                #my $ret = it |%data;
                %data ,= |run-sub-with-data &it, %data;

                @tests.append: @*TESTS;
                for @!after-each -> &exec-after-each {
                    $.debug("after each...", :$DEBUG);
                    %data ,= |run-sub-with-data &exec-after-each, %data
                }
                CATCH {
                    default {
                        error $name, $_;
                        .resume
                    }
                }
            }
        }

        await @proms if @proms;

        for keys @!after (-) $run -> &exec-after {
            $.debug("after", :$DEBUG);
            run-sub-with-data &exec-after, %data
        }
        @tests
    }
}
