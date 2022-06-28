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

    method FALLBACK($name, $args) {
        my @whitelist = <
            before
            level ws scope-increase
            float integer digit
            lower upper
            empty-lines
            double-quoted-string         single-quoted-string
            string-literal-double-quoted string-literal-single-quoted
            triple-single-quoted-string
            string-literal-triple-single-quoted
            list-delimiter
            dictionary-key dictionary-entry
            string-prefix string-prefix-raw
            perl5-package-name
        >;

        return if @whitelist.first($name);

        return if $name ~~ /^^arithmetic\-assignment\-operator/;
        return if $name ~~ /^^comparison\-operator/;

        die("No action for '$name'");
    }
}
