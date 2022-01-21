#!/bin/env raku

use lib './lib';

use Python2::Grammar;
use Python2::Actions;
use Python2::Backend::Perl5;
use Python2::Optimizer;

sub MAIN (Str $script, Bool :$no-optimize = False) {
    my Str $input = slurp( $script );

    my Str $preprocessed;

    my $ast         = Python2::Grammar.parse($input, actions => Python2::Actions);
    my $backend     = Python2::Backend::Perl5.new();
    my $optimizer   = Python2::Optimizer.new();

    my $root = $ast.made;

    $optimizer.t($root) unless $no-optimize;

    say $backend.e($root);
}
