use Python2::AST;
use Digest::SHA1::Native;
use Python2::ParseFail;

role Declaration {
    has Str $.name;
    has Str $.lexical;
    has Str $.perl-lexical;
    has Python2::AST::Type $type;

    method Str() {
        $.lexical
    }
}

class Python2::Backend::Perl5 {
    has Str $!o = '';
    has Str %.modules;
    has $.compiler is required;
    has @.scopes;

    class Scope {
        has %.names;

        method name($name) {
            %.names{$name}
        }

        method has-name($name) {
            %.names{$name}:exists
        }

        method declare(Declaration $decl) {
            die "$decl.name() already declared in this scope" if self.has-name($decl.name);
            if $decl.name ~~ /^\w+$/ {
                %.names{$decl.name} = $decl;
            }
            else {
                Nil
            }
        }
    }

    method enter-scope() {
        @.scopes.push: Scope.new;
    }

    method leave-scope() {
        die "leave-scope when no more scopes available!" unless @.scopes;
        @.scopes.pop;
    }

    multi method has-name($name) {
        @.scopes.reverse.grep(*.has-name($name)).head.name($name)
    }
    multi method has-name($name, :current-scope-only($)!) {
        @.scopes && @.scopes[*-1].has-name($name) ?? @.scopes[*-1].name($name) !! Nil
    }

    method declare(Declaration $decl) {
        @.scopes[*-1].declare($decl);
    }

    # Wrapper used for complete scripts
    has Str $!script-wrapper = q:to/END/;
        use v5.26.0;
        use utf8;
        use strict;
        use lib qw( p5lib );

        %s

        package Python2::Type::Class::main_%s {
            use Python2;
            use Python2::Stack;
            use Python2::Internals;

            use base 'Python2::Type::Main';

            # return the source of the original python file
            sub __source__ {
        return <<'PythonInput%s';
        %s
        PythonInput%s
            }

            sub __block__ {
                my ($self, $args) = @_;
                my $stack = $self->[0];

                %s
            }
        }
        END

    # Wrapper used for modules
    has Str $!module-wrapper = q:to/END/;
        package Python2::Type::Class::main_%s {
            use Python2;
            use Python2::Internals;

            use base 'Python2::Type::Main';

            # return the source of the original python file
            sub __source__ {
        return <<'PythonInput%s';
        %s
        PythonInput%s
            }

            sub __block__ {
                my ($self, $args) = @_;
                my $stack = $self->[0];

                %s
            }
        }

        # run the one-off init code
        Python2::Type::Class::main_%s->new()->__run__();
        END

    # Wrapper used for expressions
    has Str $!expression-wrapper = q:to/END/;
        use v5.26.0;
        use utf8;
        use strict;
        use lib qw( p5lib );

        %s

        package Python2::Type::CodeObject::%s {

            use base 'Python2::Type::CodeObject';

            # return the source of the original python expression
            sub __source__ {
        return <<'PythonInput%s';
        %s
        PythonInput%s
            }

            sub __call__ {
                my ($self, $locals, $parent) = @_;

                my $stack = Python2::Stack->new(
                    Python2::Stack->new($Python2::builtins, $parent),
                    $locals
                );

                my @res = eval { %s };
                $self->__handle_exception__($@) if $@ ne '';
                wantarray ? @res : $res[0]
            }
        }
        END

    # Wrapper used for DTML templates
    has Str $.template-wrapper = q:to/END/;
        use v5.26.0;
        use utf8;
        use strict;
        use lib qw( p5lib );
        use Python2::Type::CodeObject;
        use Scalar::Util qw(blessed);

        %s

        sub {
            Python2::Type::CodeObject::Anonymous->new(
        <<'PythonInput%s',
        %s
        PythonInput%s
                sub {
                    my ($self, $locals, $parent) = @_;

                    my $stack = Python2::Stack->new(
                        Python2::Stack->new($Python2::builtins, $parent),
                        $locals
                    );

                    my @res = eval { %s };
                    $self->__handle_exception__($@) if $@ ne '';
                    wantarray ? @res : $res[0]
                }
            );
        }
        END

    # code to auto-execute our main block. used for script execution and skipped when embedding
    has Str $!autoexec = q:to/END/;
        my $py2main = Python2::Type::Class::main_%s->new();
        $py2main->__run__();
        END

    # we use an array instead of a hash for faster lookups.
    # Layout:
    #[
    #    $parent,    # reference to parent stack
    #    {           # items in our scope
    #       name1 => value1,
    #       name2 => value2
    #    },
    #]

    # root node: iteral over all statements and create perl code for them
    multi method e(
        Python2::AST::Node::RootBlock $node,
        Bool :$module where { not $_ },
        Str :$embedded
    ) {
        self.enter-scope;
        for $node.declarations -> $decl {
            for $decl.decls -> $name-node {
                my $name = $name-node.name;
                unless self.has-name($name) {
                    self.declare(Declaration.new(:$name, :lexical('$lexical_' ~ $name)));
                    $!o ~= Q:c:b[my $lexical_{ $name };\n];
                }
            }
        }

        for ($node.statements) {
            $!o ~= $.e($_);
        }

        # sha1 hash of our input - used to identify the main clas
        my Str $class_sha1_hash = sha1-hex($node.input);

        my Str $output = sprintf(
            $!script-wrapper,               # wrapper / sprintf definition
            %!modules.values.join("\n"),    # python class definitions

            # name of the main package. provided when we get embedded or auto generated from sha1 hash
            $embedded ?? $embedded !! $class_sha1_hash,

            $class_sha1_hash,   # sha1 hash for source heredoc start
            $node.input,        # python2 source code for exception handling
            $class_sha1_hash,   # sha1 hash for source heredoc end
            $!o,                # block of main body
        );

        unless ($embedded) {
            $output ~= sprintf($!autoexec, $class_sha1_hash);
        }
        self.leave-scope;
        die "Imbalanced enter/leave scope detected! @.scopes.elems() scopes left" if @.scopes;

        return $output;
    }

    # compile a single expression
    multi method e(
        Python2::AST::Node::RootExpression $node,
        Str  :$embedded!
    ) {
        for ($node.nodes) {
            $!o ~= $.e($_);
        }

        # sha1 hash of our input - used for heredoc delimiter
        my Str $class_sha1_hash = sha1-hex($node.input);

        my Str $output = sprintf(
            $!expression-wrapper,           # wrapper / sprintf definition

            %!modules.values.join("\n"),    # class definitions, in expressions only used for lambdas

            # name of the class, will be Python2::Type::CodeObject::$embedded
            $embedded,

            $class_sha1_hash,   # sha1 hash for source heredoc start
            $node.input,        # python2 source code for exception handling
            $class_sha1_hash,   # sha1 hash for source heredoc end
            $!o,                # block of main body
        );

        return $output;
    }

    # handles 'from <module> import <names>'
    multi method e(
        Python2::AST::Node::RootBlock $node,     # the root node of our AST tree
        Bool :$module where { $_ },         # this method handles modules  - match where $module is true
        Str :$embedded is required,         # if we are compiling a module embedding must be set - see ::Compiler for details
        :@import-names is required,         # optional - list of names to limit what we import (from X import <imput-names>)
    ) {
        my Str $p5; # code for the complete module definition

        self.enter-scope;

        for $node.declarations -> $decl {
            for $decl.decls -> $name-node {
                my $name = $name-node.name;
                unless self.has-name($name) {
                    self.declare(Declaration.new(:$name, :lexical('$lexical_' ~ $name)));
                    $p5 ~= Q:c:b[our $lexical_{ $name };\n];
                }
            }
        }

        for $node.statements -> $node {
            # restricted by grammar - sanity check only
            die("Expected statement") unless $node ~~ Python2::AST::Node::Statement;

            # code for the current statement
            my Str $p5-statement;

            # if it's some kind of definition import it to our namespace as long as the name matches and keep it
            # around for the one-off run of the init block
            if $node.statement ~~ Python2::AST::Node::Statement::FunctionDefinition {
                $p5-statement ~= $.e($node);
            }
            elsif $node.statement ~~ Python2::AST::Node::Statement::ClassDefinition {
                $p5-statement ~= $.e($node);
            }
            elsif $node.statement ~~ Python2::AST::Node::Statement::VariableAssignment {
                # the complete node, for initialization
                $p5-statement ~= $.e($node);
            }
            else {
                $p5-statement ~= $.e($node);
            }

            $p5 ~= $p5-statement;
        }

        # sha1 hash of our input - used to identify the main clas
        my Str $class_sha1_hash = sha1-hex($node.input);

        self.leave-scope;

        my Str $output = sprintf(
            $!module-wrapper,               # wrapper / sprintf definition

            # name of the main package. provided when we get embedded or auto generated from sha1 hash
            $embedded,

            $class_sha1_hash,   # sha1 hash for source heredoc start
            $node.input,        # python2 source code for exception handling
            $class_sha1_hash,   # sha1 hash for source heredoc end
            $p5,                # the main body of the module
            $embedded
        );

        return $output;
    }

    multi method e(Python2::AST::Node::Atom $node, Bool :$declaration = False) {
        if ($node.expression ~~ Python2::AST::Node::Name) {
            my $recurse = $node.recurse ?? 1 !! 0;
            if !$declaration and self.has-name($node.expression.name) -> $lexical {
                $lexical
            }
            else {
                my $expression = $.e($node.expression);
                if $node.expression.must-resolve and not $declaration {
                    Q:s:b |Python2::Internals::getvar(\$stack, $recurse, $expression)|
                }
                else {
                    Q:s:b "Python2::Internals::getvar(\$stack, $recurse, $expression, 1)";
                }
            }
        } else {
            $.e($node.expression);
        }
    }
    multi method perl(Python2::AST::Node::Atom $node, Bool :$declaration = False) {
        if ($node.expression ~~ Python2::AST::Node::Name) {
            my $recurse = $node.recurse ?? 1 !! 0;
            if !$declaration and self.has-name($node.expression.name) -> $lexical {
                $lexical.perl-lexical
            }
            else {
                if $declaration {
                    Str
                }
                else {
                    if $node.expression.name eq 'REQUEST' {
                        '$request'
                    }
                    else {
                        my $expression = $.e($node.expression);
                        Q:s:b |Python2::Internals::getvar(\$stack, $recurse, $expression)->__tonative__|
                    }
                }
            }
        } else {
            Str
        }
    }

    multi method e(Python2::AST::Node::Locals $node) {
        return q|Python2::Builtin::Locals->new($stack)|;
    }

    multi method e(Python2::AST::Node::Statement::P5Import $node) {
        return sprintf('Python2::Internals::setvar($stack, \'%s\', Python2::Type::PerlObject->new(\'%s\'));',
            $node.name,
            $node.perl5-package-name.subst("'", "\\'", :g),
        );
    }

    multi method e(Python2::AST::Node::Statement::FromImport $node) {
        my Str $p5;

        if %*ENV<PYTHONPATH> {
            my @search-paths = %*ENV<PYTHONPATH>.split(':');

            # module name is validated by grammar
            my $module-name = $node.name;
            $module-name ~~ s:g!\.!/!;

            # unique hash of the module and the requested objects
            my Str $import-sha1-hash = sha1-hex(
                $node.name ~
                $node.import-names.names.map({ $_.name }).join(' ')
            );

            # TODO this completly ignores __init__.py
            for @search-paths -> $path {
                my $full-path = join('/', $path, "$module-name.py");

                next unless $full-path.IO.e;

                my $input = $full-path.IO.slurp;
                $p5 = $.compiler.new.compile(
                    $input,
                    :module(True),
                    :embedded($import-sha1-hash),
                    :import-names($node.import-names.names.map({ $_.name })),
                );

                last if $p5;
            }

            if $p5 {
                for $node.import-names.names>>.name -> $name {
                    self.declare(Declaration.new(:$name, :lexical("\$Python2::Type::Class::main_{$import-sha1-hash}::lexical_$name")));
                }
            }

            %!modules{$import-sha1-hash} = $p5 if $p5;
        }

        # we found not python module, fallback to perl module loading for our StdLib shims
        # if even this fails we, unlike python, abort on runtime
        if not $p5 {
            my $functions = $node.import-names.names ?? "functions => [qw/$node.import-names.names.map(*.name).join(' ')/]" !! '';
            return sprintf(
                q|Python2::Internals::import_module($stack, [{ name => '%s', name_as => '%s', %s }])|,
                $node.name, $node.name-as, $functions
            );
        }
    }

    multi method e(Python2::AST::Node::Statement::Import $node) {
        my Str $import-definition;

        for $node.modules.values -> $module {
            $import-definition ~= sprintf('{ name => \'%s\', name_as => \'%s\' }, ',
                $module<name>, $module<name-as>
            );
        }

        return sprintf('Python2::Internals::import_module($stack, [%s])', $import-definition);
    }

    multi method e(Python2::AST::Node::Name $node) {
        return sprintf("'%s'", $node.name.subst("'", "\\'", :g));
    }

    multi method e(Python2::AST::Node::ArgumentList $node) {
        my @positional-arguments;
        my @named-arguments;

        for $node.arguments -> $argument {
            if $argument.name {
                @named-arguments.append($argument);
            }
            else {
                # TODO die for mixed arguments
                @positional-arguments.append($argument);
            }
        }

        my Str $p5 = '';

        if @positional-arguments {
            # positional arguments get passed as regular arguments to the perl sub
            $p5 ~= @positional-arguments.map({
                $_.splat
                    ?? sprintf('(Python2::Internals::unsplat(%s))', $.e($_))
                    !!  $.e($_)
            }).join(', ');

            $p5 ~= ','; # to accomodate a possible named argument hashref
        }

        # named arguments get passed as a hashref to the perl method. this is always passed as the
        # last argument and will be pop()'d before processing any other arguments.
        my @nameds = @named-arguments.map({ $.e($_.name) ~ ' => ' ~ $.e($_.value) });
        @nameds.push: "(Python2::Internals::unsplatsplat($.e($node.flattened-nameds)))" if $node.flattened-nameds;
        $p5 ~= 'bless({' ~ @nameds.join(', ') ~ '}, "Python2::NamedArgumentsHash")';

        return $p5;
    }
    multi method perl(Python2::AST::Node::ArgumentList $node) {
        my @positional-arguments;

        for $node.arguments -> $argument {
            if $argument.name {
                return Str
            }
            else {
                return Str if $argument.splat;
                @positional-arguments.append($argument);
            }
        }

        my Str $p5 = '';

        if @positional-arguments {
            # positional arguments get passed as regular arguments to the perl sub
            $p5 ~= @positional-arguments.map({
                $.perl($_) // return Str
            }).join(', ');
        }

        return $p5;
    }

    multi method e(Python2::AST::Node::Argument $node) {
        return $.e($node.value);
    }
    multi method perl(Python2::AST::Node::Argument $node) {
        return $.perl($node.value);
    }

    # Statements
    # statement 'container': if it's a statement append ; to make the perl parser happy
    multi method e(
        Python2::AST::Node::Statement $node,

        # If this Block belongs to a Class this will point to it. Used to differentiate between
        # Functions and Methods.
        Python2::AST::Node::Statement::ClassDefinition $class?
    ) {
        my Str $p5  = qq|\n# line 999 "___position_{$node.start-position}_{$node.end-position}___"\n|;
               $p5 ~= $class ?? $.e($node.statement, $class) !! $.e($node.statement);
               $p5 ~= ~ ";\n";
    }

    multi method e(Python2::AST::Node::Statement::Print $node) {
        my Str $p5 = $node.values.map({
                qq|\n# line 999 "___position_{$_.start-position}_{$_.end-position}___"\n|
            ~   $.e($_)
        }).join(',');

        return sprintf('Python2::Internals::py2print(%s, {})', $p5);
    }

    multi method e(Python2::AST::Node::Statement::Del $node) {
        return sprintf('Python2::Internals::delvar($stack, \'%s\')', $node.name.name);
    }

    multi method e(Python2::AST::Node::Statement::Assert $node) {
        my Str $assertion-error = sprintf("Python2::Type::Exception->new('AssertionError', %s)",
            $node.message
                ?? $.e($node.message)
                !! ''
        );

        return sprintf('if ( not %s->__is_py_true__ ) { die %s; }',
            $.e($node.assertion),
            $assertion-error
        );
    }

    multi method e(Python2::AST::Node::Statement::Break $node) {
        return 'last;'
    }

    multi method e(Python2::AST::Node::Statement::Raise $node) {
        return $node.message
            ?? sprintf('Python2::Internals::raise(%s, %s)', $.e($node.exception), $.e($node.message))
            !! sprintf('Python2::Internals::raise(%s)', $.e($node.exception));
    }

    multi method assign(Python2::AST::Node::Atom $target, Str $expression, :@name-filter) {
        $target.expression.must-resolve = False;
        $target.recurse = False;

        return ((not @name-filter) or @name-filter.grep($target.expression.name))
            ?? Q:s:b "$.e($target) = $expression"
            !!  '';
    }

    multi method assign(Python2::AST::Node::PropertyAccess $target, Str $expression) {
        Q:s:c:b "{ $.e($target.atom) }->__setattr__(Python2::Type::Scalar::String->new($.e($target.property)), $expression, \{\})";
    }

    multi method assign(Python2::AST::Node::SubscriptAccess $target, Str $expression) {
        $target.must-resolve = False;
        Q:s:c:b "{ $.e($target.atom) }->__setitem__($.e($target.subscript), $expression, \{\})";
    }

    multi method assign(Python2::AST::Node $target) {
        Python2::ParseFail.new(:pos($target.start-position), :what("Expected name")).throw
    }

    multi method e(Python2::AST::Node::Statement::VariableAssignment $node) {
        # simple '1:1' assignment
        if ($node.targets.elems == 1) {
            return $.assign($node.targets[0], $.e($node.expression), :name-filter($node.name-filter));
        }

        else {
            my Str $p5;

            # assign our (potential) iterable to $i
            $p5 ~= sprintf('{ my $i = %s;', $.e($node.expression));

            # die if the object cannot provide a length
            $p5 ~= sprintf(q|die Python2::Type::Exception->new('TypeError', 'Expected iterable, got ' . $i->__type__) unless $i->can('__len__');|);

            # die if the elements in the object don't match the amount of targets
            $p5 ~= sprintf(q|die Python2::Type::Exception->new('ValueError', 'too many values to unpack') unless $i->__len__->__tonative__ == %i;|, $node.targets.elems);

            for $node.targets.pairs -> $target {
                $p5 ~= $.assign($target.value, '$i->__getitem__(Python2::Type::Scalar::Num->new(' ~ $target.key ~ '))', :name-filter($node.name-filter)) ~ ';';
            }

            return $p5 ~ '}';
        }


    }

    multi method e(Python2::AST::Node::Statement::ArithmeticAssignment $node) {
        my $operator = $node.operator.chop; # grammar ensures only valid operators pass thru here

        return sprintf(q|%s = Python2::Internals::arithmetic(%s, %s, '%s')|,
            $.e($node.target),
            $.e($node.target),
            $.e($node.value),
            $operator
        );
    }

    multi method e(Python2::AST::Node::Statement::Return $node) {
        return  $node.value
                ??  sprintf('return %s', $.e($node.value))
                !!  'return Python2::Type::Scalar::None->new()';
    }



    # loops
    multi method e(Python2::AST::Node::Statement::LoopFor $node) {
        my Str $p5;

        $p5 ~= qq|\n# line 999 "___position_{$node.start-position}_{$node.block.start-position}___"\n|;
        $p5 ~= sprintf('{ my $i = %s;', $.e($node.iterable));

        if ($node.names.elems > 1) {
            # TODO should support all iterables
            $p5 ~= 'die Python2::Type::Exception->new("TypeError", "expected enumerate but got " . $i->__type__) unless (($i->__type__ eq "enumerate") or ($i->__type__ eq "listiterator"));';

            $p5 ~= q:to/END/;
                while(1) {
                    my $var;
                    eval {
                        $var = $i->next();

                        die Python2::Type::Exception->new('TypeError', 'tuple expected but got ' . $var->__type__)
                            unless $var->__type__ eq 'tuple';
                END

            $p5 ~= sprintf('die Python2::Type::Exception->new("ValueError", "size of tuple does not match loop declaration, expected %i but got " . scalar(@$var)) unless scalar(@$var) == %i;', $node.names.elems, $node.names.elems);

            my Int $index = 0;
            for $node.names -> $name {
                my $lexical = self.has-name($name.name);
                $p5 ~= "$lexical = \$var->[{ $index++ }]; ";
            }

            $p5 ~= sprintf('%s', $.e($node.block));

            $p5 ~= q:to/END/;
                    };

                    if (($@) and ($@ eq 'StopIteration')) { last; } elsif ($@) { die $@; }
                }
                END
        }
        else {
            # single name, raw values from a list/tuple
            my $lexical = self.has-name($node.names[0].name);
            # Beware: can't just use foreach $lexical as then that variable will be implicitly localized, see perlsyn
            $p5 ~= "foreach (\$i->ELEMENTS) \{ $lexical = \$_; $.e($node.block) \}";
        }

        return $p5 ~ ' } ';
    }


    multi method e(Python2::AST::Node::Statement::LoopWhile $node) {
        my Str $p5 = sprintf('while (1) { last unless %s->__tonative__; %s; }', $.e($node.test), $.e($node.block));

        return $p5;
    }

    multi method e(Python2::AST::Node::Statement::Pass $node) { return ''; }

    multi method e(Python2::AST::Node::Statement::Continue $node) { return 'next'; }

    multi method e(Python2::AST::Node::ListComprehension $node) {
        my Str $p5;

        $p5 ~= sprintf('sub { my $i = %s;', $.e($node.iterable));
        $p5 ~= 'my $r = Python2::Type::List->new();';

        $p5 ~= 'die Python2::Type::Exception->new("TypeError", "expected iterable but got " . $i->__type__) unless ($i->__type__ =~ m/^list|tuple$/);';

        $p5 ~= 'foreach my $var ($i->ELEMENTS) {';
        self.enter-scope;
        self.declare(Declaration.new(:name($node.name.name), :lexical('$var')));

        $p5 ~= sprintf('next unless %s->__tonative__;', $.e($node.condition))
            if ($node.condition);

        $p5 ~= sprintf('$r->__iadd__(%s);', $.e($node.test));
        $p5 ~= '}';
        self.leave-scope;

        return $p5 ~ 'return $r; }->()';
    }

    multi method e(Python2::AST::Node::Statement::TryExcept $node) {
        my Str $p5 = sprintf('eval { %s }; if ($@) { my $e = $@; sub { %s die $@; }->()};',
            $.e($node.try-block),
            $node.except-blocks.values.map({ $.e($_) }).join(' '),
        );

        $p5 ~= sprintf('{ %s }', $.e($node.finally-block)) if $node.finally-block;

        return $p5;
    }

    multi method e(Python2::AST::Node::ExceptionClause $node) {
        return $node.exception
            ??  $node.name
                    # exception with type filter and name assignment
                    ??  sprintf(q|if (Python2::Internals::exception_matches($e,  %s)) { Python2::Internals::setvar($stack, '%s', $e); %s; return; }|,
                            $.e($node.exception),
                            $node.name.name,
                            $.e($node.block)
                        )

                    # exception with type filter only
                    !!  sprintf(q|if (Python2::Internals::exception_matches($e, %s)) { %s; return; }|, $.e($node.exception), $.e($node.block))

            # generic 'except:'
            !! $.e($node.block) ~ ' return;';
    }

    multi method e(Python2::AST::Node::Test $node) {
        my $p5;

        if ($node.condition) {
            $p5 ~= sprintf(
                '(sub { my $p = %s; $p // die Python2::Type::Exception->new("NameError", "TODO - varname"); ref($p) eq "CODE" ? $p :$p->__tonative__; }->() ? ',
                $.e($node.condition)
            );
        }

        $p5 ~= sprintf('sub { my $p = %s; $p // die Python2::Type::Exception->new("NameError", "TODO - varname"); $p; }->()', $.e($node.left));

        if ($node.condition) {
            $p5 ~= sprintf(': sub { my $p = %s; $p // die Python2::Type::Exception->new("NameError", "TODO - varname"); $p; }->())', $.e($node.right));
        }

        return $p5;
    }

    multi method e(Python2::AST::Node::Statement::If $node) {
        my Str $p5 = qq|\n# line 999 "___position_{$node.start-position}_{$node.block.start-position}___"\n|;

        $p5 ~= sprintf('if ( %s->__is_py_true__ ) { %s }', $.e($node.test), $.e($node.block));

        for $node.elifs -> $elif {
            $p5 ~= $.e($elif);
        }

        $p5 ~= sprintf('else { %s }', $.e($node.else)) if $node.else;

        return $p5;
    }

    # TODO we don't implement all of with yet, no calls to __exit__
    # TODO this is 'good enough' for our fileIO use case since we close the FH on scope
    # TODO exit anyway.
    multi method e(Python2::AST::Node::Statement::With $node) {
        my Str $p5 = qq|\n# line 999 "___position_{$node.start-position}_{$node.block.start-position}___"\n|;

        # self-contained block to ensoure $p does not conflict
        $p5 ~= '{';

        # the object with references (with <object> as <variable>)
        $p5 ~= sprintf('my $o = %s;', $.e($node.test));

        # call __enter__ which must return the variable to be assigned
        $p5 ~= q|my $p = $o->__enter__($stack, bless({}, 'Python2::NamedArgumentsHash'));|;

        # assign to <variable>
        $p5 ~= sprintf('Python2::Internals::setvar($stack, %s, $p);', $.e($node.name));

        # our code block
        $p5 ~= $.e($node.block);

        # TODO - we don't implement python's arguments to __exit__
        $p5 ~= q|$o->__exit__($stack, Python2::Type::Scalar::None->new(), Python2::Type::Scalar::None->new(), Python2::Type::Scalar::None->new(), bless({}, 'Python2::NamedArgumentsHash'));|;

        # end of self-contained block to ensoure $p does not conflict
        $p5 ~= '}';

        return $p5;
    }

    multi method e(Python2::AST::Node::Statement::ElIf $node) {
        return sprintf('elsif (%s->__is_py_true__) { %s }', $.e($node.test), $.e($node.block));
    }

    multi method e(Python2::AST::Node::Statement::Test::Comparison $node) {
        my %operators =
            '=='        => '__eq__',
            '!='        => '__ne__',
            '<'         => '__lt__',
            '>'         => '__gt__',
            '<='        => '__le__',
            '>='        => '__ge__',
            'is'        => '__is__',
            'is not'    => '__is__',
            'in'        => '__contains__',
            'not in'    => '__contains__';

        if $node.operators == 1 {
            my $negate = $node.operators[0] ∈ ('not in', 'is not');
            my $operator = %operators{$node.operators[0]};
            my ($left, $right) = $node.operands;
            ($left, $right) = ($right, $left) if $operator eq '__contains__';

            return $negate
                ??  sprintf('%s->%s(%s)->__negate__',
                        $.e($left),
                        $operator,
                        $.e($right),
                    )
                !!  sprintf('%s->%s(%s)',
                        $.e($left),
                        $operator,
                        $.e($right),
                    );
        }
        else {
            my sub comparer(Pair $op) {
                my $negate = $op.value ∈ ('not in', 'is not');
                my $operator = %operators{$op.value};
                my ($left, $right) = ('$operand_' ~ $op.key, '$operand_' ~ ($op.key + 1));
                ($left, $right) = ($right, $left) if $op eq '__contains__';

                my $res = Q:s:b "$left\->$operator\($right)";
                $res ~= '->__negate__' if $negate;
                $res ~= '->__is_py_true__';
                $res
            }
            Q:s "(do { my ($node.operands.keys.map({"\$operand_$_"}).join(', ')) = ($node.operands.values.map({"$.e($_)"}).join(', ')); Python2::Type::Scalar::Bool->new($node.operators.pairs.map(&comparer).join(' and ')) })";
        }
    }

    multi method e(Python2::AST::Node::Test::Logical $node) {
        return $.e($node.values[0]) unless $node.condition;

        if ($node.condition.condition eq 'not') {
            # not always returns a bool
            return sprintf('Python2::Type::Scalar::Bool->new(not (%s->__is_py_true__))', $.e($node.values[0]));
        }
        elsif ($node.condition.condition eq 'or') {
            # or returns the first true value or, if all are false, the last value
            my Str $p5;
            $p5 ~= 'sub { my $t;';

            for $node.values -> $value {
                $p5 ~= sprintf('$t = %s; return $t if $t->__is_py_true__;', $.e($value));
            }

            # if we didn't return before the all values are false - return the last one
            $p5 ~= 'return $t;';

            $p5 ~= '}->()';

            return $p5;
        }
        else {
            # and returns the first false value or, of all are true, the last value
            my Str $p5;
            $p5 ~= 'sub { my $t;';

            for $node.values -> $value {
                $p5 ~= sprintf('$t = %s; return $t unless $t->__is_py_true__;', $.e($value));
            }

            # if we didn't return before the all values are true - return the last one
            $p5 ~= 'return $t;';

            $p5 ~= '}->()';

            return $p5;
        }
    }

    multi method e(
        Python2::AST::Node::Statement::FunctionDefinition $node,

        # If this Function belongs to a Class this will point to it triggering Method generation
        Python2::AST::Node::Statement::ClassDefinition    $class?
    ) {
        self.enter-scope;

        my Str $block;

        # local stack frame for this function
        $block ~= Q:b/my $self = shift; my $stack = $self->{stack}->clone;\n/;
        $block ~= Q:b/my $nameds = pop if @_ and defined $_[-1] and ref($_[-1]) eq "Python2::NamedArgumentsHash";\n/;
        $block ~= Q:b/unshift @_, $self->{object};\n/ if $class;

        # argument definition containing, if present, default vaules
        my Str $argument-definition = '';
        for $node.argument-list -> $argument {
            my $name = $argument.name.name;
            self.declare(Declaration.new(:$name, :lexical('$lexical_' ~ $name)));
            if $argument.splat == 1 {
                $block ~= Q:c:b[my $lexical_{ $name } = Python2::Type::Tuple->new(@_);\n];
            }
            elsif $argument.splat == 2 {
                $block ~= Q:c:b[my $lexical_{ $name } = Python2::Type::Dict->new(%$nameds);\n];
            }
            else {
                $block ~= Q:c:b[my $lexical_{ $name } = $nameds && exists $nameds->\{{ $name }\} ? delete $nameds->\{{ $name }\} : @_ ? shift : { $argument.default-value ?? $.e($argument.default-value) !! 'undef' };\n];
            }
        }

        for $node.declarations -> $decl {
            for $decl.decls -> $name-node {
                my $name = $name-node.name;
                unless self.has-name($name, :current-scope-only) {
                    self.declare(Declaration.new(:$name, :lexical('$lexical_' ~ $name)));
                    $block ~= Q:c:b[my $lexical_{ $name };\n];
                }
            }
        }

        # the actual function body
        my $body = $.e($node.block);

        $block ~= $body;


        # if the function body contains a return statement it will execute before this
        $block   ~= 'return Python2::Type::Scalar::None->new();';

        self.leave-scope;

        if $class {
            return "Python2::Internals::setvar(\$stack, $.e($node.name), Python2::Type::Method->new(\$stack, \$self, $.e($node.name), sub \{ $block \}));";
        }
        else {
            my $lexical = self.has-name($node.name.name, :current-scope-only);
            unless $lexical {
                my $name = $node.name.name;
                self.declare(Declaration.new(:$name, :lexical('$lexical_' ~ $name)));
                $lexical = '$lexical_' ~ $node.name.name;
            }
            return "Python2::Internals::setvar(\$stack, $.e($node.name), $lexical = Python2::Type::Def->new(\$stack, $.e($node.name), sub \{ $block \}));";
        }
    }

    multi method e(Python2::AST::Node::LambdaDefinition $node) {
        my Str $block;

        self.enter-scope;

        # local stack frame for this lambda
        $block ~= 'my $self = shift; my $stack = $self->{stack}->clone;' ~ "\n";
        $block ~= 'my $named_args = (@_ && defined $_[-1] && (ref($_[-1])// "") eq "Python2::NamedArgumentsHash") ? pop : {};' ~ "\n";

        # get arguments
        for $node.argument-list -> $argument {
            my $name = $argument.name.name;
            my $lexical = self.declare(Declaration.new(:$name, :lexical('$__arg__' ~ $name)));
            $lexical = "my $lexical = " if $lexical;
            my $input = $argument.splat == 1
                ?? 'Python2::Type::List->new(@_)'
                !! $argument.splat == 2
                    ?? 'Python2::Type::Dict->__from_hash__(%$named_args)'
                    !! 'shift';
            $block ~= "        Python2::Internals::setvar(\$stack, '$argument.name.name()', {$lexical}$input);\n";
        }

        # the actual function body
        $block ~= sprintf(Q:b'        my $retvar = %s;\n        return $retvar;', $.e($node.block));

        self.leave-scope;

        return Q:s:b[Python2::Type::Lambda->new(\$stack, sub { $block })];
    }

    multi method e(Python2::AST::Node::Statement::ClassDefinition $node) {
        self.enter-scope;

        for $node.declarations -> $decl {
            for $decl.decls -> $name-node {
                my $name = $name-node.name;
                # Prevent us from finding a lexical with same name in outer scope
                self.declare(Declaration.new(:$name, :lexical("Python2::Internals::getvar(\$stack, 0, $.e($name-node), 1)"))) unless self.has-name($name, :current-scope-only);
            }
        }

        my $body = $.e($node.block, $node);

        self.leave-scope;

        my $lexical = self.has-name($node.name.name, :current-scope-only);
        unless $lexical {
            my $name = $node.name.name;
            self.declare(Declaration.new(:$name, :lexical('$lexical_' ~ $name)));
            $lexical = '$lexical_' ~ $node.name.name;
        }
        return sprintf('Python2::Internals::setvar($stack, \'%s\', %s = Python2::Type::Object->new(%s, %s, sub { my $self = $_[0]; my $stack = $self->{stack};  %s }));',
            $node.name.name.subst("'", "\\'", :g),
            $lexical,
            $.e($node.name),
            $node.base-class ?? $.e(Python2::AST::Node::Atom.new(expression => $node.base-class)) !! 'undef',
            $body,
        );
    }


    # Expressions
    multi method e(Python2::AST::Node::Expression::Container $node) {
        # grammar ensures we only get valid operators here
        my %operator-method-map =
            '|'     => '__or__',
            '&'     => '__and__',
            '^'     => '__xor__',
            '<<'    => '__lshift__',
            '>>'    => '__rshift__',
            ;

        my $p5;

        my @expressions = $node.expressions.clone;
        my @operators   = $node.operators.clone;

        # initial left element
        my $left-element = @expressions.shift;

        my $operator;
        my $right-element;

        $p5 ~= qq|\n# line 999 "___position_{$left-element.start-position}_{$left-element.end-position}___"\n|;
        $p5 ~= sprintf('sub { my $left = %s;', $.e($left-element));

        # as long as we have operators remaining there must be more expressions
        while @operators.elems > 0 {
            $operator       = @operators.shift;
            $right-element  = @expressions.shift;

            $p5 ~= qq|\n# line 999 "___position_{$right-element.start-position}_{$right-element.end-position}___"\n|;

            $p5 ~= sprintf(
                '$left = $left->%s(%s);',
                %operator-method-map{$operator},
                $.e($right-element)
            );
        }

        $p5 ~= 'return $left; }->()';

        return $p5;
    }

    multi method e(Python2::AST::Node::PropertyAccess $node) {
        Q:s:b "$.e($node.atom)\->__getattr__(Python2::Type::Scalar::String->new($.e($node.property)), {})";
    }

    multi method e(Python2::AST::Node::SubscriptAccess $node) {
        $node.subscript.target
            ?? Q:s:c:b "{ $.e($node.atom) }->__getslice__($.e($node.subscript))"
            !! $node.must-resolve
                ?? Q:s:c:b "{ $.e($node.atom) }->__getitem__($.e($node.subscript))"
                !! Q:s:c:b "{ $.e($node.atom) }->__getitem__($.e($node.subscript), 1)";
    }

    multi method e(Python2::AST::Node::Call $node) {
        Q:s:c:b "{ $.e($node.atom) }->__call__($.e($node.arglist))";
    }
    multi method perl(Python2::AST::Node::Call $node) {
        if not $node.arglist.arguments and $node.atom.type ~~ Python2::AST::ReturnsZMSObject and my $perl = $.perl($node.atom) {
            "$perl\->()"
        }
        else {
            Q:s:c:b "{ $.e($node.atom) }->__call__($.e($node.arglist))";
        }
    }

    multi method e(Python2::AST::Node::Call::Name $node) {
        my Str $p5;
        $p5 ~= qq|\n# line 999 "___position_{$node.start-position}_{$node.name.end-position}___"\n|;
        $p5 ~= Q:s:c:b "{ $.e($node.name) }->__call__($.e($node.arglist))";
    }
    multi method perl(Python2::AST::Node::Call::Name $node) {
        if not $node.arglist.arguments and $node.name.type ~~ Python2::AST::ReturnsZMSObject and my $perl = $.perl($node.name) {
            if $node.name.expression ~~ Python2::AST::Node::Name && $node.name.expression.name eq 'this' {
                '$context'
            }
            else {
                "$perl\->()"
            }
        }
        else {
            my $name = $node.name.expression.name;
            $node.context.^name;
            if ($node.context ~~ Python2::AST::ZMSObject and $node.context.method-known($name)) {
                my $args-perl = $.perl($node.arglist) orelse return Str;
                "\$context->$name\($args-perl)"
            }
            else {
                Str
            }
        }
    }

    multi method e(Python2::AST::Node::Call::Method $node) {
        my Str $p5;
        $p5 ~= Q:s:b "(do { my \$p = $.e($node.atom);";
        $p5 ~= Q:s:b "my @a = ($.e($node.arglist));";
        $p5 ~= qq|\n# line 999 "___position_{$node.start-position}_{$node.name.end-position}___"\n|;
        $p5 ~= Q:s:b "\$p->can('$node.name.name()') ? \$p->$node.name.name()\(@a) : \$p->__getattr__(Python2::Type::Scalar::String->new('$node.name.name()'), {})->__call__(@a) })";
    }
    multi method perl(Python2::AST::Node::Call::Method $node) {
        return Str unless $node.atom.type ~~ Python2::AST::PerlObject;

        my $atom-perl = $.perl($node.atom) orelse return Str;
        my $args-perl = $.perl($node.arglist) orelse return Str;
        my Str $p5;

        if $node.atom.type.method-known($node.name.name) {
            Q:s:b "$atom-perl\->$node.name.name()\($args-perl)";
        }
        else {
            $p5 ~= Q:s:b "(do { my \$p = $atom-perl;";
            $p5 ~= Q:s:b "my @a = ($args-perl);";
            $p5 ~= qq|\n# line 999 "___position_{$node.start-position}_{$node.name.end-position}___"\n|;
            $p5 ~= Q:s:b "\$p->can('$node.name.name()') ? \$p->$node.name.name()\(@a) : \$p->__getattr__('$node.name.name()', 0, 1)->(@a) })";
        }
    }

    multi method e(Python2::AST::Node::Expression::ArithmeticExpression $node) {
        my $p5;

        my @operations = $node.operations.clone;

        # initial left element
        my $left-element = @operations.shift;

        my $operation;
        my $right-element;

        $p5 ~= qq|\n# line 999 "___position_{$left-element.start-position}_{$left-element.end-position}___"\n|;
        $p5 ~= sprintf('(do { my $left = %s;', $.e($left-element));

        while @operations.elems {
            $operation      = @operations.shift;
            $right-element  = @operations.shift;

            $p5 ~= qq|\n# line 999 "___position_{$right-element.start-position}_{$right-element.end-position}___"\n|;

            $p5 ~= sprintf(
                q|$left = Python2::Internals::arithmetic($left, %s, '%s');|,
                $.e($right-element),
                $.e($operation)
            );
        }

        $p5 ~= '$left })';

        return $p5;
    }

    multi method e(Python2::AST::Node::Expression::ArithmeticOperator $node) {
        return $node.arithmetic-operator;
    }

    multi method e(Python2::AST::Node::Expression::Literal::String $node) {
        # TODO various escape sequences
        my $string = $node.value
            .subst('\"',    '"',    :g)
            .subst('\\\'',  "'",    :g)
        ;

        # r'string' (python raw strings)
        unless $node.raw {
            $string = $string
                .subst('\\\\',  '\\',   :g)
                .subst('\\n',   "\n",   :g)
                .subst('\\r',   "\r",   :g)
                .subst('\\t',   "\t",   :g);
        }

        my $class = $node.unicode
            ??  'Python2::Type::Scalar::Unicode'
            !!  'Python2::Type::Scalar::String';

        if $string.contains("'") {
            my $p5;

            $p5 ~= "\nsub \{ my \$s = <<'MAGICendOfStringMARKER';\n";
            $p5 ~= $string;
            $p5 ~= Q:c:b "\nMAGICendOfStringMARKER\n; chomp(\$s); return {$class}->new(\$s); }->()";
        }
        else {
            Q:c "{$class}->new('{$string}')"
        }
    }
    multi method perl(Python2::AST::Node::Expression::Literal::String $node) {
        # TODO various escape sequences
        my $string = $node.value
            .subst('\"',    '"',    :g)
            .subst('\\\'',  "'",    :g)
        ;

        # r'string' (python raw strings)
        unless $node.raw {
            $string = $string
                .subst('\\\\',  '\\',   :g)
                .subst('\\n',   "\n",   :g)
                .subst('\\r',   "\r",   :g)
                .subst('\\t',   "\t",   :g);
        }

        if $string.contains("'") {
            my $p5;

            $p5 ~= "\nsub \{ my \$s = <<'MAGICendOfStringMARKER';\n";
            $p5 ~= $string;
            $p5 ~= Q:c:b "\nMAGICendOfStringMARKER\n; chomp(\$s); return \$s; }->()";
        }
        else {
            Q:c "'{$string}'"
        }
    }

    multi method e(Python2::AST::Node::Expression::Literal::Integer $node) {
        return sprintf('Python2::Type::Scalar::Num->new(%s)', $node.value);
    }
    multi method perl(Python2::AST::Node::Expression::Literal::Integer $node) {
        return $node.value;
    }

    multi method e(Python2::AST::Node::Expression::Literal::Float $node) {
        return sprintf('Python2::Type::Scalar::Num->new(%s)', $node.value)
    }
    multi method perl(Python2::AST::Node::Expression::Literal::Float $node) {
        return $node.value;
    }

    multi method e(Python2::AST::Node::Subscript $node) {
        return $node.target
            ?? sprintf('%s, %s', $.e($node.value), $.e($node.target))
            !! sprintf('%s', $.e($node.value));
    }

    # list handling
    multi method e(Python2::AST::Node::Expression::ExpressionList $node) {
        return sprintf('Python2::Type::List->new(%s)',
            $node.expressions.map({
                    qq|\n# line 999 "___position_{$_.start-position}_{$_.end-position}___"\n|
                ~   self.e($_)
            }).join(', ')
       );
    }

    multi method e(Python2::AST::Node::Expression::TestList $node) {
        # empty tuple "x = ()" becomes an empty tuple
        if ($node.tests.elems == 0) {
            return 'Python2::Type::Tuple->new()';
        }

        # tuple with multiple values "x = (1, 2, 3)" - regular tuple
        elsif $node.tests.elems > ($node.trailing-comma ?? 0 !! 1) {
            return sprintf('Python2::Type::Tuple->new(%s)',
                $node.tests.map({
                        qq|\n# line 999 "___position_{$_.start-position}_{$_.end-position}___"\n|
                    ~   self.e($_)
                }).join(', ')
            );
        }

        elsif $node.tests.elems == 1 {
            # if a tuple would only contain a single element python disregards the parenthesis
            return sprintf('%s', $.e($node.tests[0]));
        }

        else {
            die("Invalid TestList"); # should be unreachable
        }
    }
    multi method perl(Python2::AST::Node::Expression::TestList $node) {
        # empty tuple "x = ()" becomes an empty tuple
        if ($node.tests.elems == 0) {
            return 'Python2::Type::Tuple->new()->__tonative__()';
        }

        # tuple with multiple values "x = (1, 2, 3)" - regular tuple
        elsif $node.tests.elems > ($node.trailing-comma ?? 0 !! 1) {
            return sprintf('Python2::Type::Tuple->new(%s)->__tonative__()',
                $node.tests.map({
                        qq|\n# line 999 "___position_{$_.start-position}_{$_.end-position}___"\n|
                    ~   self.e($_)
                }).join(', ')
            );
        }

        elsif $node.tests.elems == 1 {
            # if a tuple would only contain a single element python disregards the parenthesis
            return $.perl($node.tests[0]);
        }

        else {
            die("Invalid TestList"); # should be unreachable
        }
    }

    # dictionary handling
    multi method e(Python2::AST::Node::Expression::DictionaryDefinition $node) {
        return sprintf('Python2::Type::Dict->new(%s)',
            $node.entries.map({
                    qq|\n# line 999 "___position_{$_.key.start-position}_{$_.key.end-position}___"\n|
                ~   $.e($_.key)

                ~   ' => '

                ~   qq|\n# line 999 "___position_{$_.value.start-position}_{$_.value.end-position}___"\n|
                ~   $.e($_.value)
            }).join(', ')
       );
    }

    multi method e(Python2::AST::Node::DictComprehension $node) {
        my Str $p5;

        $p5 ~= sprintf('sub { my $i = %s;', $.e($node.iterable));
        $p5 ~= 'my $r = Python2::Type::Dict->new();';

        $p5 ~= 'foreach my $var ($i->ELEMENTS) {';
        # die if the object cannot provide a length
        $p5 ~= sprintf(q|die Python2::Type::Exception->new('TypeError', 'Expected iterable, got ' . $var->__type__) unless $var->can('__len__');|);

        # die if the elements in the object don't match the number of targets
        $p5 ~= sprintf(q|die Python2::Type::Exception->new('ValueError', 'too many values to unpack') unless $var->__len__->__tonative__ == %i;|, $node.names.elems);

        for $node.names.kv -> $i, $target {
            $p5 ~= sprintf(q|Python2::Internals::setvar($stack, %s, $var->__getitem__(Python2::Type::Scalar::Num->new(%i)));|, $.e($target), $i);
        }

        $p5 ~= sprintf('next unless %s->__tonative__;', $.e($node.condition))
            if ($node.condition);

        $p5 ~= sprintf('$r->__setitem__(%s, %s);', $.e($node.key), $.e($node.value));
        $p5 ~= '}';

        return $p5 ~ 'return $r; }->()';
    }

    # set handling
    multi method e(Python2::AST::Node::Expression::SetDefinition $node) {
        return sprintf('Python2::Type::Set->new(%s)',
            $node.entries.map({
                    qq|\n# line 999 "___position_{$_.start-position}_{$_.end-position}___"\n|
                ~   $.e($_)
            }).join(', ')
       );
    }

    multi method e(
        Python2::AST::Node::Block $node,

        # If this Block belongs to a Class this will point to it. Used to differentiate between
        # Functions and Methods.
        Python2::AST::Node::Statement::ClassDefinition $class?
    ) {
        if $class {
        }
        return sprintf('%s', $node.statements.map({
            # Pass the Class on to any FunctionDefinition to trigger Method creation.
            ($_ ~~ Python2::AST::Node::Statement) and ($_.statement ~~ Python2::AST::Node::Statement::FunctionDefinition)
                ?? self.e($_, $class)
                !! self.e($_)
        }).join(''));
    }


    # Fallback
    multi method e(Any:D $node) {
        die("Perl 5 backed for node not implemented: {$node.^name}");
    }

    multi method e(Any:U $node) {
        die("Perl 5 backed for undefined node not implemented: {$node.^name}");
    }

    # Fallback
    multi method perl(Any:D $node) {
        Str # Can't do Perl directly, so caller will generate Python through $.e instead
    }

    multi method perl(Any:U $node) {
        die("Perl 5 backed for undefined node not implemented: {$node.^name}");
    }
}
