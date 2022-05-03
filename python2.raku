#!/bin/env raku

use lib './lib';

use Python2::Compiler;

sub MAIN (Str $script, Bool :$no-optimize = False, Bool :$dumpast = False) {
    my Str $input = slurp( $script );

    my $compiler = Python2::Compiler.new(
        optimize => $no-optimize ?? False !! True,
        dumpast  => $dumpast,
    );

    say $compiler.compile($input);
}
