#!/bin/env raku

use lib './lib';

use Python2::Grammar;
use Python2::Actions;
use Python2::Backend::Perl5;

sub MAIN (Str $script) {
    my Str $input = slurp( $script );

    my Str $preprocessed;

    my $ast     = Python2::Grammar.parse($input, actions => Python2::Actions);
    my $backend = Python2::Backend::Perl5.new();

    my $root = $ast.made;

    say $backend.e($root);
}
