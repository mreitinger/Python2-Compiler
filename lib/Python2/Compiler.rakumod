use Python2::Grammar;
use Python2::Actions;
use Python2::Backend::Perl5;
use Python2::Optimizer;

class Python2::Compiler {
    has Bool $.optimize = True;
    has $!parser        = Python2::Grammar.new();
    has $!backend       = Python2::Backend::Perl5.new();
    has $!optimizer     = Python2::Optimizer.new();
    has $!actions       = Python2::Actions.new();

    method compile (Str $input) {
        my $ast = $!parser.parse($input, actions => $!actions);
        my $root = $ast.made;

        $!optimizer.t($root) if $.optimize;

        return $!backend.e($root);
    }

}
