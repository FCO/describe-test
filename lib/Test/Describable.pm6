use Test::Describable::Describe;
use Test::Describable::Funcs;
use Test::Describable::Containers;
use Test::Describable::CLI;

sub EXPORT {
    {
        '&it'           => &it,
        '&describe'     => &describe,
        '&before'       => &before,
        '&before-each'  => &before-each,
        '&after'        => &after,
        '&after-each'   => &after-each,
        '&MAIN'         => &MAIN,
        '&ok'           => &ok,
        '&is'           => &is,
        '&pass'         => &pass,
    }
}
