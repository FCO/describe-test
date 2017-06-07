use Test::Describable::Funcs;
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
    multi method run(Bool :$DEBUG, Set :$run = Set.new, :%data) {
        my @tests;
        for keys @!before (-) $run -> &exec-before {
            $.debug("before", :$DEBUG);
            my $res = exec-before;
            $res = await $res if $res ~~ Promise;
            %data ,= |$res if $res ~~ Associative
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
                    my @keys = &exec-before-each.signature.params.map: *.name.substr: 1;
                    my %pairs = @keys Z=> %data{|@keys};
                    my $res;
                    if %pairs {
                        $res = exec-before-each |%pairs
                    } else {
                        $res = exec-before-each
                    }
                    $res = await $res if $res ~~ Promise;
                    %data ,= |$res if $res ~~ Associative
                }
                $.debug("running it", :$DEBUG);
                my @*TESTS;
                #my $ret = it |%data;
                my $res = it |%(%data{&it.signature.params.map: *.name.substr: 1}:kv);
                if $res ~~ Promise {
                    $res = await $res;
                    %data ,= |$res if $res ~~ Associative
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

        await @proms if @proms;

        for keys @!after (-) $run -> &exec-after {
            $.debug("after", :$DEBUG);
            my $res = exec-after;
            await $res if $res ~~ Promise;
        }
        @tests
    }
}
