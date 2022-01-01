use Python2::AST;
use Data::Dump;

use Python2::Backend::Perl5::ObjectAccess;

class Python2::Backend::Perl5
    does Python2::Backend::Perl5::ObjectAccess
{
    has Str $!o =
        "use v5.26.0;\n" ~
        "use strict;\n" ~
        "use lib qw( p5lib );\n" ~
        "use Python2;\n\n" ~
        'my $stack = [];' ~ "\n\n" ~
        'use constant { PARENT => 0, VARIABLES => 1, FUNCTIONS => 2, CLASSES => 3 };' ~ "\n\n";

    # we use an array instead of a hash for faster lookups.
    # Layout:
    #[
    #    $parent,    # reference to parent stack
    #    {},         # variables in our scope
    #    {},         # function definitions in our scope
    #    {},         # class definitions in our scope
    #]

    # root node: iteral over all statements and create perl code for them
    multi method e(Python2::AST::Node::Root $node) {
        for ($node.nodes) {
            $!o ~= $.e($_);
        }

        return $!o;
    }

    # Statements
    # statement 'container': if it's a statement append ; to make the perl parser happy
    multi method e(Python2::AST::Node::Statement $node) {
        return $.e($node.statement) ~ ";\n";
    }

    multi method e(Python2::AST::Node::Statement::Print $node) {
        return 'Python2::py2print(' ~ $.e($node.value) ~ ");\n";
    }

    multi method e(Python2::AST::Node::Statement::VariableAssignment $node) {
        if ($node.list-or-dict-element) {
            return 'Python2::setvar_e($stack, \'' ~ $node.variable-name ~ "', " ~ $.e($node.list-or-dict-element) ~ ", " ~ $.e($node.expression) ~ ");";
        } else {
            return 'Python2::setvar($stack, \'' ~ $node.variable-name ~ "', " ~ $.e($node.expression) ~ ");";
        }
    }

    multi method e(Python2::AST::Node::Statement::Return $node) {
        return "return { $.e($node.value) }"
    }



    # loops
    multi method e(Python2::AST::Node::Statement::LoopFor $node) {
        # TODO should we prefix variable names with something to prevent clashes?
        my $p5 = 'foreach my $var (@{ ' ~ $.e($node.iterable) ~ '->elements }) {' ~ "\n";
        $p5 ~=   '    Python2::setvar($stack, \''~ $node.variable-name ~ '\', $var);' ~ "\n";
        $p5 ~=   $.e($node.block);

        #for $node.expressions -> $expression {
        #    $p5 ~= $.e($expression);
        #    $p5 ~= ','; # TODO trailing slash
        #}

        $p5 ~= "}\n";

        return $p5;
    }

    multi method e(Python2::AST::Node::Statement::TryExcept $node) {
        my $p5 = 'eval { ' ~ $.e($node.try-block) ~ ' } or do { ' ~ $.e($node.except-block) ~ ' } ';
        $p5 ~= '; {' ~ $.e($node.finally-block) ~ '}' if $node.finally-block;

        return $p5;
    }

    multi method e(Python2::AST::Node::Statement::If $node) {
        my $p5 = 'if (' ~ $.e($node.test) ~ ') {' ~ "\n" ~ $.e($node.block) ~ "}";
        $p5 ~= ' else {' ~ $.e($node.else) ~ '}' if $node.else;
        $p5
    }

    multi method e(Python2::AST::Node::Statement::Test::Expression $node) {
        return $.e($node.expression);
    }

    multi method e(Python2::AST::Node::Statement::Test::Comparison $node) {
        return  'Python2::compare(' ~
                $.e($node.left) ~ ', ' ~
                $.e($node.right) ~ ', \'' ~
                $node.comparison-operator ~ '\')';
    }

    multi method e(Python2::AST::Node::Statement::FunctionDefinition $node) {
        my $p5 = 'Python2::register_function($stack, \'' ~ $node.function-name ~ '\', sub {' ~ "\n";

        $p5 ~= 'my $arguments = shift;' ~ "\n";
        $p5 ~= 'my $stack = [ $stack ];' ~ "\n";

        for $node.argument-list -> $argument {
            $p5 ~= 'Python2::setvar($stack, \'' ~ $argument ~ '\', shift @$arguments);' ~ "\n";
        }

        $p5   ~= $.e($node.block);
        $p5   ~= "});"
    }

    multi method e(Python2::AST::Node::Statement::ClassDefinition $node) {
        my $p5 = Q:c "Python2::create_class($stack, ";
        $p5   ~= Q:c "'{ $node.class-name }', ";
        $p5   ~=     "sub \{ my \$stack = shift; { $.e($node.block) }\})";
    }

    # Expressions
    multi method e(Python2::AST::Node::Expression::Container $node) {
        return $.e($node.expression);
    }

    # TODO ArithmeticOperation's should probably(?) operate on Literal::Integer
    multi method e(Python2::AST::Node::Expression::ArithmeticOperation $node) {
        my $p5;

        for $node.operations -> $operation {
            $p5 ~= $.e($operation);
        }

        return $p5;
    }

    multi method e(Python2::AST::Node::Expression::ArithmeticOperator $node) {
        return $node.arithmetic-operator;
    }

    multi method e(Python2::AST::Node::Expression::Literal::String $node) {
        return "'" ~ $node.value.subst("'", "\\'", :g) ~ "'";
    }

    multi method e(Python2::AST::Node::Expression::Literal::Integer $node) {
        return $node.value;
    }

    multi method e(Python2::AST::Node::Expression::Literal::Float $node) {
        return $node.value;
    }

    multi method e(Python2::AST::Node::Expression::VariableAccess $node) {
        return 'Python2::getvar($stack, \'' ~ $node.variable-name ~ "')";
    }

    multi method e(Python2::AST::Node::Statement::InstanceVariableAssignment $node) {
        my Str $p5;
        if ($node.list-or-dict-element) {
            # assuming object.array[0]
            # fetch stack for object
            $p5 ~= 'Python2::setvar_e(' ~ $.e($node.object-access) ~ '->{stack}, ';

            # add target variable ('array')
            $p5 ~= '\'' ~ $node.target-variable.variable-name.Str ~ '\', ';

            # add item ([0])
            $p5 ~= $.e($node.list-or-dict-element) ~ ',';
        } else {
            # assuming object.item
            # fetch stack for object
            $p5 ~= 'Python2::setvar(' ~ $.e($node.object-access) ~ '->{stack}, ';

            # add target variable ('item')
            $p5 ~= '\'' ~ $node.target-variable.variable-name.Str ~ '\', ';
        }

        # new value to set
        $p5 ~=   $.e($node.expression);
        $p5 ~=   ")";

        return $p5;
    }

    multi method e(Python2::AST::Node::Expression::DictionaryAccess $node) {
        #get the dictionary object

        my $p5 ~= 'Python2::getvar($stack, \'' ~ $node.dictionary-name ~ '\')';
           $p5 ~= "->element({ $node.key })";
        return $p5;
    }

    # function calls
    multi method e(Python2::AST::Node::Expression::FunctionCall $node) {
        my $p5 = 'Python2::call($stack, \'' ~ $node.function-name ~ '\', [';

        for $node.arguments -> $argument {
            $p5 ~= $.e($argument);
            $p5 ~= ','; # TODO trailing slash
        }

        $p5 ~=   '])' ~ "\n";

        return $p5;
    }




    # list handling
    multi method e(Python2::AST::Node::Expression::ListDefinition $node) {
        my $p5 = 'Python2::Type::List->new(';

        for $node.expressions -> $expression {
            $p5 ~= $.e($expression);
            $p5 ~= ','; # TODO trailing slash
        }

        $p5 ~= ')';

        return $p5;
    }


    # dictionary handling
    multi method e(Python2::AST::Node::Expression::DictionaryDefinition $node) {
        my $p5 = 'Python2::Type::Dict->new(';

        for $node.entries.kv -> $dictionary-key, $expression {
            $p5 ~= $dictionary-key ~ ' => ' ~ $.e($expression); #TODO needs quoting etc for key
            $p5 ~= ','; # TODO trailing slash
        }

        $p5 ~= ')';

        return $p5;
    }

    multi method e(Python2::AST::Node::Block $node) {
        my $p5;

        for $node.statements -> $statement {
            $p5 ~= $.e($statement);
        }

        return '{' ~ $p5 ~ '}';
    }


    # Fallback
    multi method e($node) {
        die("Perl 5 backed for node not implemented: " ~ Dump($node));
    }
}
