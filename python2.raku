#!/bin/env raku

use lib './lib';

use Python2::Compiler;

multi sub MAIN (Str $script, Bool :$no-optimize = False, Bool :$dumpast = False, Str :$embedded) {
    my Str $input = slurp( $script );

    my $compiler = Python2::Compiler.new(
        optimize => $no-optimize ?? False !! True,
        dumpast  => $dumpast,
        embedded => $embedded,
    );

    say $compiler.compile($input);
}

multi sub MAIN (Bool :$no-optimize = False, Bool :$dumpast = False, Str :$embedded) {
    my Str $input = $*IN.slurp;

    my $compiler = Python2::Compiler.new(
        optimize => $no-optimize ?? False !! True,
        dumpast  => $dumpast,
        embedded => $embedded,
    );

    say $compiler.compile($input);
}
