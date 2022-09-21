use Python2::Actions::Statements;
use Python2::Actions::Expressions;
use Python2::AST;

class Python2::Actions
    is Python2::Actions::Statements
    is Python2::Actions::Expressions
{
    method TOP ($/) {
        my $root = Python2::AST::Node::Root.new(
            input => $/.orig,
        );

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
            start-position  => $/.from,
            end-position    => $/.to,
            comment         => $0.Str
        );
    }

    method end-of-line-comment($/) {
        make Python2::AST::Node::Comment.new(
            start-position  => $/.from,
            end-position    => $/.to,
            comment         => $0.Str
        );
    }

    method FALLBACK($name, $args) {
        my @whitelist = <
            ww dws end-of-statement
            before
            level ws scope-increase
            float integer digit
            lower upper splat
            empty-lines
            double-quoted-string         single-quoted-string
            string-literal-double-quoted string-literal-single-quoted
            triple-single-quoted-string         triple-double-quoted-string
            string-literal-triple-single-quoted string-literal-triple-double-quoted
            list-delimiter
            dictionary-entry set-entry
            string-prefix string-prefix-raw string-prefix-unicode
            perl5-package-name extended-list-delimiter
            or-expression-operator  xor-expression-operator
            and-expression-operator shift-expression-operator
            full-slice start-slice end-slice
            not-in
        >;

        return if @whitelist.first($name);

        return if $name ~~ /^^arithmetic\-assignment\-operator/;
        return if $name ~~ /^^comparison\-operator/;

        die("No action for '$name'");
    }
}
