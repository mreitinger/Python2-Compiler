use Python2::Actions::Statements;
use Python2::Actions::Expressions;
use Python2::AST;

package Python2::Actions {
    role Fallback {
        # ensures we have a action for every rule/token - some we dont process into AST nodes
        # the whitelist takes care of that.
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
                import-module-as-name
            >;

            return if @whitelist.first($name);

            return if $name ~~ /^^arithmetic\-assignment\-operator/;
            return if $name ~~ /^^comparison\-operator/;

            die("No action for '$name'");
        }
    }

    # Actions for complete Python 2 Grammar (Expressions & Statements)
    class Complete
        does Python2::Actions::Statements
        does Python2::Actions::Expressions
        does Python2::Actions::Fallback
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
    }

    # Actions for Python 2 Expression Grammar only
    class ExpressionsOnly
        does Python2::Actions::Expressions
        does Python2::Actions::Fallback
    {
        method TOP ($/) {
            my $root = Python2::AST::Node::Root.new(
                input => $/.orig,
                nodes => $/<expression>.made,
            );

            $/.make($root);
        }
    }
}