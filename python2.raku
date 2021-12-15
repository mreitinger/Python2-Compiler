use lib './lib';

use Python2::Grammar;
use Python2::Actions;
use Python2::Backend::Perl5;

my Str $input = slurp();
my Str $preprocessed;

# preprocess input:
# - add a ';' to the end of every statement so the Grammar has something easier to work with
# - add '{' and '}' around every indentation level so the Grammar can parse scope levels
#
# TODO: best case: this would be handled by a pure raku Grammar so we can get reliable information
# TODO: about the location in case of errors
#
# TODO: migrate to a dedicated Preprocessor module
#
# TODO: this does not handle multiple levels of indentation decreasing at once

# the current indentation level we are at as determined by the number of spaces at the start
# of the line. previous as in 'indentation level on the previous line'.
my $previous_indentation_level = 0;

# the size of the previous indentation ("number of spaces between the previous block and this one")
# if nested blocks get 'closed' in the same line this is used to place the correct amount of closing
# brackets.
my $previous_indentation_size = 0;

for $input.split("\n") -> $line is copy {
    $line.chomp;

    # skip empty lines: they stay at the same scope/indentation level as the line before
    next if ($line ~~ m/^^$$/);

    # place a ; at the end of every line unless it is a compound ('multiline') statement like
    # for loops, if statements etc
    $line ~= ';' unless $line ~~ m/\:$$/;

    # find the indentation level for this line. assume '0' if there is no whitespace to be found.
    # current as in 'indentation level on the current line'
    # TODO: this allowd too much: python is picky about mixing tabs and spaces.
    $line ~~ m/^(\s+)/;
    my $current_indentation_level = ($0 ?? $0.Str.chars !! 0);

    # indentation level increased, start a new block
    if ($current_indentation_level > $previous_indentation_level) {
        $line ~~ s/^/\{\n/;

        $previous_indentation_size = ($current_indentation_level - $previous_indentation_level);

        $previous_indentation_level = $current_indentation_level;
    }

    # indentation level decreasted, close the block
    if ($current_indentation_level < $previous_indentation_level) {
        my $closed_block_count =
            ($previous_indentation_level - $current_indentation_level) / $previous_indentation_size;

        $line ~~ s/^/\};\n/ for 1 .. $closed_block_count;

        $previous_indentation_level = $current_indentation_level;
    }

    $preprocessed ~= "$line\n";
}

my $ast     = Python2::Grammar.parse($preprocessed, actions => Python2::Actions);
my $backend = my $t = Python2::Backend::Perl5.new();

my $root = $ast.made;

say $t.e($root);
