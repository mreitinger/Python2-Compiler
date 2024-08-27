use DTML::AST;
use Digest::SHA1::Native;
use Python2::Backend::Perl5;

unit class DTML::Backend::Perl5
    is Python2::Backend::Perl5;

sub term:sym<pre>() {
    '    ' x $*LEVEL
}

sub indent() {
    $*LEVEL++
}

sub dedent() {
    $*LEVEL--
}

sub line($code) {
    $*CODE ~= pre ~ $code ~ "\n"
}

sub indented(&content) {
    indent;
    &content();
    dedent;
}

multi block(&content) {
    line '{';
    indent;
    &content();
    dedent;
    line '};';
}

multi block($tag, &content) {
    line Q:s'{ #$tag';
    indent;
    &content();
    dedent;
    line Q:s'}; #/$tag';
}

sub stmt($stmt, &content) {
    line $stmt ~ ' {';
    indented {
        &content();
    }
    line '}';
}

multi method e(DTML::AST::Template $node, :$embedded) {
    my $*LEVEL = 4;
    my $*DTML-SOURCE = $node.input;
    my $body = Q:s:b:f:to/CODE/.chomp;

                sub {
                    my (\$self, \$request, \$context, \$dynamics, \$lexpads) = @_;
                    my \$body = '';\n$node.chunks.map({self.e($_)}).join("\n")
                    \$body;
                }
           
    CODE
    my Str $class_sha1_hash = sha1-hex($node.input);
    sprintf(
        $.template-wrapper,           # wrapper / sprintf definition

        %.modules.values.join("\n"),    # python class definitions

        $class_sha1_hash,   # sha1 hash for source heredoc start
        $node.input,   # python2 source code for exception handling
        $class_sha1_hash,   # sha1 hash for source heredoc end
        $body,         # block of main body
    );
}

multi method e(DTML::AST::Content $node) {
    my $*CODE;
    if 1 < $node.content.lines {
        line Q{chomp($body .= <<~'END');};
        indented {
            line $_ for $node.content.lines;
            line 'END'
        }
    }
    else {
        line "\$body .= '$node.content().subst(Q['], Q[\'], :g)';"
    }
    $*CODE
}

multi method e(@chunks) {
    $*CODE ~= self.e($_) for @chunks;
}

multi method e(DTML::AST::Expression $node, :$lexical = '') {
    $node.word
        ?? self.has-name($node.word)
            ?? "do \{ my \$res = {$lexical ?? "$lexical = " !! ''}$.has-name($node.word); blessed \$res \&\& \$res->isa('Python2::Type') ? \$res->__tonative__ : \$res \}"
            !! $lexical
                ?? "do \{ my \$res = \$self->eval_word(\$context, \$dynamics, \$lexpads, '$node.word()', -1); $lexical = Python2::Internals::convert_to_python_type(\$res); \$res \}"
                !! "\$self->eval_word(\$context, \$dynamics, \$lexpads, '$node.word()', -1)"
        !! "do \{ my \$res = {$lexical ?? "$lexical = " !! ''}$.e($node.expression); blessed \$res \&\& \$res->isa('Python2::Type') ? \$res->__tonative__ : \$res \}"
}

multi method e(DTML::AST::Var $node) {
    if ($node.expression.word // '') eq 'REQUEST' {
        return pre ~ Q:b '$body .= $request->dump_debug_information;\n';
    }

    my $var = Q:s:f "$.e($node.expression) // ''";
    my $*CODE = '';
    line
        "\{ local \$Data::Dumper::Maxdepth = ({$node.attr('dump').value or 2});"
        ~ qq! my \$output = "$node.expression.escaped-gist(): " . Data::Dumper::Dumper(scalar $var);!
        ~ " warn \$output;"
        ~ Q[ $body .= '<pre>' . HTML::Escape::escape_html($output) . '</pre>'; }]
        if $node.has-attr('dump');

    $var = "($var)->strftime($.e($node.fmt))" if $node.fmt;
    $var = "DTML::Renderer::cut_at_size($var, $.e($node.size)" ~ ($node.etc.defined ?? ", $.e($node.etc)" !! '') ~ ')'
        if $node.size;
    $var = "HTML::Escape::escape_html($var)"        if $node.has-attr('html_quote');
    $var = "URI::Escape::uri_escape_utf8($var)"    if $node.has-attr('url_quote');
    $var = "DTML::Renderer::newline_to_br($var)"      if $node.has-attr('newline_to_br');
    $var = "DTML::Renderer::links_target_blank($var)" if $node.has-attr('links_target_blank');

    $var = "DTML::Renderer::remove_attributes($var, $.e($node.remove_attributes))"
        if $node.remove_attributes;
    $var = "DTML::Renderer::remove_tags($var, $.e($node.remove_tags))"
        if $node.remove_tags;
    $var = Q:s:f[DTML::Renderer::tag_content_only("" . $var, $.e($node.tag_content_only))]
        if $node.tag_content_only;

    line "\$body .= $var;";
    $*CODE
}

multi method e(DTML::AST::Return $node) {
    my $var = Q:s:f "$.e($node.expression) // ''";
    my $*CODE = '';

    $var = "HTML::Escape::escape_html($var)"    if $node.has-attr('html_quote');
    $var = "URI::Escape::uri_escape_utf8($var)" if $node.has-attr('url_quote');

    line "return $var;";
    $*CODE
}

multi method e(DTML::AST::If $node) {
    my $*CODE = '';

    block 'if', {
        line "my \$value = $.e($node.expression);";
        stmt "$node.if() (\$value and (not ref \$value or ref \$value ne 'ARRAY' or \@\$value > 0))", {
            $.e($node.then);
        }
        $*CODE ~= $.e($_) for $node.elif;
        if $node.else {
            stmt 'else', {
                $.e($node.else);
            };
        }
    };

    $*CODE
}

multi method e(DTML::AST::Elif $node) {
    my $*CODE = '';

    stmt "elsif ($.e($node.expression))", {
        $.e($node.chunks);
    }

    $*CODE
}

multi method e(DTML::AST::Let $node) {
    my $*CODE = '';

    block 'let', {
        self.enter-scope;
        line 'push @$lexpads, {};';
        my %lexicals;
        for ($node.declarations) { # May be empty. Yes, people write <dtml-let> in templates
            my $attr = .name;
            my $lexical = '';
            if $attr ~~ /^\w+$/ { # Can use lexicals!
                $lexical = "\$lexical_$attr";
                if %lexicals{$attr}++ {
                    line Q:b:s:f"\$lexpads->[-1]{'$attr'} = $.e($_.expression, :$lexical);";
                }
                else {
                    line Q:b:s:f"my $lexical; \$lexpads->[-1]{'$attr'} = $.e($_.expression, :$lexical);";
                    self.declare($attr, "\$lexical_$attr");
                }
            }
            else {
                line Q:b:s:f"\$lexpads->[-1]{'$attr'} = $.e($_.expression);";
            }
        }

        $.e($node.chunks);

        line 'pop @$lexpads;';
        self.leave-scope;
    }

    $*CODE
}

multi method e(DTML::AST::Include $node) {
    my $*CODE = '';
    my $dir = $node.file.subst('.', '/', :g);

    line '$body .= $self->exec_dtml_file(';
    line '    $_,';
    line '    $context,';
    line '    {%$dynamics, map { %$_ } @$lexpads},';
    line ') foreach $context';
    line '    ->instance';
    line '    ->template_loader';
    line "    ->list_directory('$dir');";

    $*CODE
}

multi method e(DTML::AST::With $node) {
    my $*CODE = '';

    block 'with', {
        line Q:s:f:b [local \$self->{context} = local \$local_context->{context} = my \$context = $.e($node.expression);];
        $.e($node.chunks);
    }

    $*CODE
}

multi method e(DTML::AST::Attribute $node) {
    my $v = $node.value;
    $v.defined
        ?? $node.value.match(/^\d+$/) ?? $node.value !! "'$node.value-escaped()'"
        !! $.e($node.expression)
}

multi method e(DTML::AST::In $node) {
    my $*CODE = '';

    block 'in', {
        line 'my $values = ' ~ $.e($node.expression) ~ ";";
        line 'my @values = (defined $values and ($values eq "0" or $values eq ""))'
            ~ ' ? () : (ref $values and ref $values eq "ARRAY") ? @$values : $values;';
        line '@values = @{ $values[0] }'
            ~ ' if @values == 1 and ref $values[0] and ref $values[0] eq "ARRAY"'
            ~ ' and Python2::InlinePythonAPI::py_is_tuple($values[0]);'
            if $node.expression.word;

        if $node.reverse or $node.has-attr('reverse') {
            line '@values = reverse @values;';
        }
        if $node.start {
            line "\{ my \$start = $.e($node.start); splice \@values, 0, \$start - 1 if \$start > 1};";
        }
        if $node.end {
            my $offset = $.e($node.end) ~ ($node.start ?? " - $.e($node.start) + 1" !! '');
            line "\{my \$offset = $offset; splice \@values, \$offset if \$offset < scalar \@values\};";
        }
        if $node.size {
            line "\{my \$size = $.e($node.size); splice \@values, \$size if \@values > \$size\};";
        }
        line 'my $i = 0;';
        stmt 'foreach my $sequence_item (@values)', {;
            self.enter-scope;
            line 'my $sequence_number = $i + 1;';
            line 'my $sequence_key;';
            line 'if ('
                ~ '$sequence_item'
                ~ ' and ref $sequence_item eq "ARRAY"'
                ~ ' and @$sequence_item == 2'
                ~ ' and Python2::InlinePythonAPI::py_is_tuple($sequence_item)'
                ~ ') {';

            indented {
                line '$sequence_key  = $sequence_item->[0];';
                line '$sequence_item = $sequence_item->[1];';
            }
            line '}';
            line 'my $outer = $context;';
            line 'local $self->{context} = local $local_context->{context} = my $context = blessed $sequence_item ? $sequence_item : $outer;';
            line 'push @$lexpads, {';
            indented {
                self.declare('sequence-item', 'Python2::Internals::convert_to_python_type($sequence_item)');
                line '(defined $sequence_key ? (\'sequence-key\' => $sequence_key) : ()),';
                line "'sequence-item'   => \$sequence_item,";
                line "'sequence-index'  => \$i,";
                line "'sequence-number' => \$sequence_number,";
                line "'sequence-even'   => \$i % 2 == 0,";
                line "'sequence-odd'    => \$i % 2,";
                line "'sequence-start'  => \$i == 0,";
                line "'sequence-end'    => \$i == \@values - 1,";
                line "'sequence-length' => scalar \@values,";
                if ($node.has-attr('prefix')) {
                    my $prefix = $node.attr('prefix').value.subst(Q'\', Q'\\').subst("'", Q"\'", :g);
                    line "(defined \$sequence_key ? ('{$prefix}_key' => \$sequence_key) : ()),";
                    self.declare("{$prefix}_item", 'Python2::Internals::convert_to_python_type($sequence_item)');
                    line "'{$prefix}_item'   => \$sequence_item,";
                    line "'{$prefix}_index'  => \$i,";
                    line "'{$prefix}_number' => \$i + 1,";
                    line "'{$prefix}_even'   => \$i % 2 == 0,";
                    line "'{$prefix}_odd'    => \$i % 2,";
                    line "'{$prefix}_start'  => \$i == 0,";
                    line "'{$prefix}_end'    => \$i == \@values - 1,";
                    line "'{$prefix}_length' => scalar \@values,";
                }
            }
            line '};';

            $.e($node.chunks);

            line 'pop @$lexpads;';
            line '$i++;';
            self.leave-scope;
        }
    };

    $*CODE
}

multi method e(DTML::AST::Call $node) {
    pre ~ 'my () = ' ~ $.e($node.expression) ~ ";\n" # The my () silences void context warnings
}

multi method e(DTML::AST::Try $node) {
    my $*CODE = '';

    if $node.except {
        block {
            line 'my $eval_body = eval {';
            indented {
                line 'my $body;';
                $.e($node.chunks);
                line '$body;';
            }
            line '};';
            stmt 'if ($@ ne "")', {
                $.e($node.except);
            }
            line '$body .= $eval_body // ""';
        }
    }
    else {
        line '$body .= eval {';
        indented {
            line 'my $body;';
            $.e($node.chunks);
            line '$body;';
        }
        line '};';
    }

    $*CODE
}

multi method e(DTML::AST::Zms $node) {
    my $*CODE = '';

    my $root = $node.obj ?? $.e($node.obj) !! '$context';
    my @attrs;
    @attrs.push: "root => $root";
    @attrs.push: "id => $.e($node.id)" if $node.id;
    @attrs.push: "level => $.e($node.level)" if $node.level;
    @attrs.push: $node.default-value-attribute('expanded', 0);
    @attrs.push: $node.use-caption-images;
    @attrs.push: $node.default-value-attribute('link_min_level', 0);
    @attrs.push: "activenode => $.e($node.activenode)" if $node.activenode;
    @attrs.push: "treenode_filter => $.e($node.treenode_filter)" if $node.treenode_filter;
    @attrs.push: "caption => $.e($node.caption)" if $node.caption;
    @attrs.push: "class => $.e($node.class)" if $node.class;
    @attrs.push: "max_children => $.e($node.max_children)" if $node.max_children;
    @attrs.push: "content_switch => $.e($node.content_switch)" if $node.content_switch;

    line '$body .= ' ~ "$root\->navigation_tree(";
    indented {
        line "$_," for @attrs;
    }
    line ');';

    $*CODE
}

multi method e(DTML::AST::Comment $node) {
    ''
}
