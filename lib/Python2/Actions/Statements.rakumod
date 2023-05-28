use Python2::AST;
use Data::Dump;

role Python2::Actions::Statements {
    method statement ($/) {
        die("Statement Action expects exactly one child but we got { $/.values.elems }")
            unless $/.values.elems == 1;

        $/.make(Python2::AST::Node::Statement.new(
                start-position  => $/.from,
                end-position    => $/.to,
                statement       => $/.values[0].made,
        ));
    }

    # we could handle this within the grammar but this way we can keep all of our sanity checking
    # in place as-is.
    method statement-pass ($/) {
        $/.make(Python2::AST::Node::Statement::Pass.new(
            start-position  => $/.from,
            end-position    => $/.to,
        ));
    }

    method statement-continue ($/) {
        $/.make(Python2::AST::Node::Statement::Continue.new(
            start-position  => $/.from,
            end-position    => $/.to,
        ));
    }

    method statement-p5import($/) {
        $/.make(Python2::AST::Node::Statement::P5Import.new(
            start-position  => $/.from,
            end-position    => $/.to,
            perl5-package-name  => $/<perl5-package-name>.Str,
            name                => $/<name>.Str
        ));
    }

    method statement-import($/) {
        my @modules = $/<import-module-as-name>.map({
            %(
                name        => $_<dotted-name>.Str,
                name-as     => $_<name> ?? $_<name>.Str !! $_<dotted-name>.Str.split('.').tail()
            )
        });

        $/.make(Python2::AST::Node::Statement::Import.new(
            start-position      => $/.from,
            end-position        => $/.to,
            modules             => @modules,
        ));
    }

    method statement-from($/) {
        $/.make(Python2::AST::Node::Statement::FromImport.new(
            start-position      => $/.from,
            end-position        => $/.to,
            name                => $/<dotted-name>.Str,
            import-names        => $/<import-names>.made,
        ));
    }

    method import-names($/) {
        $/.make(Python2::AST::Node::Statement::ImportNames.new(
            start-position      => $/.from,
            end-position        => $/.to,
            names               => $/<name>.map({ $_.made }),
        ));
    }

    method statement-print($/) {
        $/.make(Python2::AST::Node::Statement::Print.new(
            start-position  => $/.from,
            end-position    => $/.to,
            values          => $/<test>.map({ $_.made }),
        ));
    }

    method statement-del($/) {
        $/.make(Python2::AST::Node::Statement::Del.new(
            start-position  => $/.from,
            end-position    => $/.to,
            name            => $/<name>.made
        ));
    }

    method statement-assert($/) {
        $/.make(Python2::AST::Node::Statement::Assert.new(
            start-position  => $/.from,
            end-position    => $/.to,
            assertion       => $/<test>[0].made,
            message         => $/<test>[1] ?? $/<test>[1].made !! Nil,
        ));
    }

    method statement-break($/) {
        $/.make(Python2::AST::Node::Statement::Break.new(
            start-position  => $/.from,
            end-position    => $/.to,
        ));
    }

    method statement-raise($/) {
        $/.make(Python2::AST::Node::Statement::Raise.new(
            exception   => $/<test>[0].made,
            message     => $/<test>[1] ?? $/<test>[1].made !! Nil,
        ));
    }

    method variable-assignment($/) {
        $/.make(Python2::AST::Node::Statement::VariableAssignment.new(
            start-position  => $/.from,
            end-position    => $/.to,
            targets         => $/<power>.map({ $_.made }),
            expression      => $/<test-list>.made
        ));
    }

    method arithmetic-assignment($/) {
        $/.make(Python2::AST::Node::Statement::ArithmeticAssignment.new(
            start-position  => $/.from,
            end-position    => $/.to,
            target      => $/<power>.made,
            value       => $/<test>.made,
            operator    => $/<arithmetic-assignment-operator>.Str,
        ));
    }

    method statement-loop-for($/) {
        $/.make(Python2::AST::Node::Statement::LoopFor.new(
            start-position  => $/.from,
            end-position    => $/.to,
            names           => $/<name>.List.map({ $_.made }),
            iterable        => $/<expression>.made,
            block           => $/<block>.made,
        ));
    }

    method statement-loop-while($/) {
        $/.make(Python2::AST::Node::Statement::LoopWhile.new(
            start-position  => $/.from,
            end-position    => $/.to,
            test            => $/<test>.made,
            block           => $/<block>.made,
        ));
    }

    method statement-if($/) {
        $/.make(Python2::AST::Node::Statement::If.new(
            start-position  => $/.from,
            end-position    => $/.to,
            test            => $/<test>.made,
            block           => $/<if>.made,
            elifs           => $/<statement-elif>.List.map({ $_.made }),
            else            => $/<else>.made
        ));
    }

    method statement-with($/) {
        $/.make(Python2::AST::Node::Statement::With.new(
            start-position  => $/.from,
            end-position    => $/.to,
            test            => $/<test>.made,
            block           => $/<block>.made,
            name            => $/<name>.made
        ));
    }

    method statement-elif($/) {
        $/.make(Python2::AST::Node::Statement::ElIf.new(
            start-position  => $/.from,
            end-position    => $/.to,
            test            => $/<test>.made,
            block           => $/<blorst>.made,
        ));
    }

    method statement-try-except($/) {
        $/.make(Python2::AST::Node::Statement::TryExcept.new(
            start-position  => $/.from,
            end-position    => $/.to,
            try-block       => $/<block>[0].made,
            except-blocks   => $/<exception-clause>.values.map({ $_.made }),
            finally-block   => $/<block>[1] ?? $/<block>[1].made !! Python2::AST::Node,
        ));
    }

    method exception-clause($/) {
        $/.make(Python2::AST::Node::ExceptionClause.new(
            start-position  => $/.from,
            end-position    => $/.to,
            exception       => $/<name>[0] ?? $/<name>[0].made !! Nil,
            name            => $/<name>[1] ?? $/<name>[1].made !! Nil,
            block           => $/<block>.made,
        ));
    }

    method function-definition($/) {
        $/.make(Python2::AST::Node::Statement::FunctionDefinition.new(
            start-position  => $/.from,
            end-position    => $/.to,
            name            => $/<name>.made,
            argument-list   => $/<function-definition-argument-list>.made,
            block           => $/<block>.made,
        ));
    }

    method class-definition($/) {
        $/.make(Python2::AST::Node::Statement::ClassDefinition.new(
            start-position  => $/.from,
            end-position    => $/.to,
            name            => $/<name>[0].made,
            block           => $/<block>.made,
            base-class      => $/<name>[1] ?? $/<name>[1].made !! Nil,
        ));
    }

    method statement-return ($/) {
        $/.make(Python2::AST::Node::Statement::Return.new(
            start-position  => $/.from,
            end-position    => $/.to,
            value           => $/.values[0] ?? $/.values[0].made !! Nil,
        ))
    }

    multi method block($/ where $<statement>) {
        my $block = Python2::AST::Node::Block.new(
            start-position  => $/.from,
            end-position    => $/.to,
        );

        for $/<statement> -> $statement {
            $block.statements.push($statement.made);
        }

        $/.make($block);
    }

    method blorst($/) {
        make $<block> ?? $<block>.made !! $<statement>.made;
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
}
