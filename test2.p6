use lib "lib";
use Test::Describable;

describe "test 001" => {
    before-each {
        note "before-each"
    }
    describe "sub test 001.001" => {
        it "001.001.1" => {
            sleep 1;
            is 42, 42, "42 == 42"
        }
        it "001.001.2" => {
            sleep 1;
            is 13, 13, "13 == 13"
        }
    }
    describe "sub test 001.002" => {
        it "001.002.1" => {
            sleep 1;
            is 42, 13, "42 == 13"
        }
        it "001.002.2" => {
            sleep 1;
            is 13, 42, "13 == 42"
        }
    }
}

describe "test 002" => {
    describe "^10" => {
        for ^10 -> $i {
            it "002.$i" => {
                is $i, "$i", "num $i is equal to str $i";
            }
            it {
                is $i, "$i"
            }
        }
    }
    describe "async test" => {
        it "async" => {
            start {
                sleep 1;
                is "waited", "waited", "waited"
            }
        }
    }
}

describe "fail" => {
    it "throw" => {
        die "deu ruim"
    }
}
