use lib "lib";
use Test::Describable;

describe "bla" => {
    before      { say "BEGIN"; a => 41 }
    before-each -> :$a { a => $a + 1 }
    after       -> :$a { say "FINISHED: $a" }
    after-each { say "ALMOST FINISHED" }

    describe "bla.bla" => {
        it "1" => -> :$a {is $a, 42}
        it "2" => -> :$a {is $a, 42}
    }
    describe "bla.ble" => -> :$a {
        it "3" => -> :$a {is $a, 42}
        it "4" => -> :$a {is $a, 42}
    }
}
