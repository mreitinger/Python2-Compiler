use DTML::Grammar;
use DTML::Actions;
use DTML::Backend::Perl5;

unit class DTML::Compiler;

method compile(Str $code) {
    my $backend = DTML::Backend::Perl5.new(:compiler(self));
    my $ast = DTML::Grammar.new.parse($code, :actions(DTML::Actions.new)).ast;
    $backend.e($ast);
}
