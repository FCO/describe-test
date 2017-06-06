use lib ".";
use Describe;

describe "bla" => {
    my $a;
    before      { start { say "BEGIN!!!"; $a = 42 } }
    before-each { start $a++ }
    after       { say "FINISHED" }
    after-each  { say "ALMOST FINISHED" }

    describe "bla.bla" => {
        it "1" => {ok True, $a}
        it "2" => {ok True, $a}
    }
    describe "bla.ble" => {
        it "3" => {ok True, $a}
        it "4" => {ok True, $a}
    }
}
