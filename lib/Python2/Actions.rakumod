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
            $root.nodes.push(Python2::AST::Node::Statement.new(
                statement => $statement.made
            )) unless $statement === Nil;
        }

        $/.make($root);
    }

    method empty-line-at-same-scope ($/) {
        # dummy
    }

    method empty-line-scope-change ($/) {
        # dummy
    }

    method scope-decrease ($/) {
        # dummy
    }

    method empty-line ($/) {
        # dummy
    }
}