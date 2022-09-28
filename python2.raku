#!/bin/env raku

use lib './lib';

use Python2::Compiler;

multi sub MAIN (
    Str  $script,
    Bool :$no-optimize = False,
    Bool :$dumpast = False,
    Str  :$embedded,
    Bool :$preprocess-tabs = False,
) {
    my Str $input = slurp( $script );

    # replace leading tabs with 4 spaces. this only handles a very limited
    # amount of input and is only intended to support a few existing scripts
    # until they can be adjusted.
    $input ~~ s:g[^^\t+] = '    ' x $/.chars
        if $preprocess-tabs;

    my $compiler = Python2::Compiler.new(
        optimize => $no-optimize ?? False !! True,
        dumpast  => $dumpast,
    );

    say $compiler.compile($input, :$embedded);
}

multi sub MAIN (Bool :$no-optimize = False, Bool :$dumpast = False, Str :$embedded) {
    my Str $input = $*IN.slurp;

    my $compiler = Python2::Compiler.new(
        optimize => $no-optimize ?? False !! True,
        dumpast  => $dumpast,
    );

    say $compiler.compile($input, :$embedded);
}

multi sub MAIN (Bool :$no-optimize = False, Bool :$dumpast = False, Str :$embedded!, Str :$expression!) {
    my $compiler = Python2::Compiler.new(
        optimize => $no-optimize ?? False !! True,
        dumpast  => $dumpast,
    );

    say $compiler.compile-expression($expression, :$embedded);
}
