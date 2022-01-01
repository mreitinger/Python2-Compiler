use Python2::Actions::Statements;
use Python2::Actions::Expressions;
use Python2::AST;

class Python2::Actions
    is Python2::Actions::Statements
    is Python2::Actions::Expressions
{
    method TOP ($/) {
        my $root = Python2::AST::Node::Root.new();

        for $<statement> -> $statement {
            $root.nodes.push($statement.made)
                unless $statement === Nil;
        }

        $/.make($root);
    }

    method scope-decrease ($/) {
        # dummy
    }

    method non-code($/) {
        make $<comment>.made if $<comment>;
    }

    method comment($/) {
        make Python2::AST::Node::Comment.new(
            comment => $0.Str
        );
    }
}
