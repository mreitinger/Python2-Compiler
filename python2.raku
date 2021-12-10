use lib './lib';

use Python2::Grammar;
use Python2::Actions;
use Python2::Backend::Perl5;

my Str $input = slurp();
my Str $preprocessed;

# preprocess input: add ; to the end of every so the Grammar has something easier to work with
# TODO: best case: this would be handled by a pure raku Grammar so we can get reliable information
# TODO: about the location in case of errors
for $input.split("\n") -> $line is copy {
    $line.chomp;

    $line ~= ';';

    $preprocessed ~= "$line\n";
}

my $ast     = Python2::Grammar.parse($preprocessed, actions => Python2::Actions);
my $backend = my $t = Python2::Backend::Perl5.new();

my $root = $ast.made;

say $t.e($root);
