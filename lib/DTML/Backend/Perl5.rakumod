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

multi method e(DTML::AST::Expression $node) {
    $node.word
        ?? "\$self->eval_word(\$context, \$dynamics, \$lexpads, '$node.word()', -1)"
        !! "do \{ my \$res = $.e($node.expression); blessed \$res \&\& \$res->isa('Python2::Type') ? \$res->__tonative__ : \$res \}"
}

multi method e(DTML::AST::Var $node) {
    if ($node.expression.word // '') eq 'REQUEST' {
        return pre ~ Q:b 'return $request->dump_debug_information;\n';
    }

    my $var = Q:s:f "$.e($node.expression) // ''";
    my $*CODE = '';
    line
        "\{ local \$Data::Dumper::Maxdepth = ({$node.attr('dump') or 2});"
        ~ qq! my \$output = "$node.expression.escaped-gist(): " . Data::Dumper::Dumper(scalar $var);!
        ~ " warn \$output;"
        ~ Q[ $body .= '<pre>' . HTML::Escape::escape_html($output) . '</pre>'; }]
        if $node.has-attr('dump');

    $var = "($var)->strftime('$node.attr("fmt")')" if $node.has-attr('fmt');
    $var = "DTML::Renderer::cut_at_size($var, $node.attr('size')" ~ ($node.has-attr('etc') ?? ", '$node.attr("etc")'" !! '') ~ ')'
        if $node.has-attr('size');
    $var = "HTML::Escape::escape_html($var)"        if $node.has-attr('html_quote');
    $var = "URI::Escape::uri_escape_utf8($var)"    if $node.has-attr('url_quote');
    $var = "DTML::Renderer::newline_to_br($var)"      if $node.has-attr('newline_to_br');
    $var = "DTML::Renderer::links_target_blank($var)" if $node.has-attr('links_target_blank');

    $var = "DTML::Renderer::remove_attributes($var, '$node.attr("remove_attributes")')"
        if $node.has-attr('remove_attributes');
    $var = "DTML::Renderer::remove_tags($var, '$node.attr("remove_tags")')"
        if $node.has-attr('remove_tags');
    $var = Q:s:f[DTML::Renderer::tag_content_only("" . $var, '$node.attr('tag_content_only')')]
        if $node.has-attr('tag_content_only');

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
        line 'push @$lexpads, {};';
        my %lexicals;
        for ($node.declarations) { # May be empty. Yes, people write <dtml-let> in templates
            my $attr = .name;
            my $lexical = $attr ~~ /^\w+$/
                ?? "{%lexicals{$attr}++ ?? '' !! 'my '}\$lexical_$attr = "
                !! '';
            line Q:b:s:f"$lexical\$lexpads->[-1]{'$attr'} = $.e($_.expression);";
        }

        $.e($node.chunks);

        line 'pop @$lexpads;';
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

        if ($node.attributes) {
            if $node.has-attr('reverse') {
                line '@values = reverse @values;';
            }
            if $node.has-attr('start') {
                line "splice \@values, 0, $node.attr('start') - 1 if $node.attr('start') > 1;";
            }
            if $node.has-attr('end') {
                my $offset = $node.attr('end') - ($node.has-attr('start') ?? $node.attr('start') - 1 !! 0);
                line "splice \@values, $offset if $offset < scalar \@values;";
            }
            if $node.has-attr('size') {
                line "splice \@values, $node.attr('size') if \@values > $node.attr('size');";
            }
        }
        line 'my $i = 0;';
        stmt 'foreach my $sequence_item (@values)', {;
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
                    my $prefix = $node.attr('prefix');
                    line "(defined \$sequence_key ? ('{$prefix}_key' => \$sequence_key) : ()),";
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

sub tonative($val) {
    'do { my $val = ' ~ $val ~ '; blessed $val && $val->isa("Python2::Type") ? $val->__tonative__ : $val }'
}

multi method e(DTML::AST::Zms $node) {
    my $*CODE = '';

    my $root = $node.obj ?? tonative($.e($node.obj)) !! '$context';
    line '$body .= ' ~ $root
        ~ "->navigation_tree(\n" ~ (
            $node.value-attribute('id'),
            $node.level ?? "level => { tonative($.e($node.level)) }" !! Slip,
            "root => $root",
            $node.default-value-attribute('expanded', 0),
            $node.use-caption-images,
            $node.default-value-attribute('link_min_level', 0),
            $node.activenode ?? "activenode => { tonative($.e($node.activenode)) }" !! Slip,
            $node.treenode_filter ?? "treenode_filter => { tonative($.e($node.treenode_filter)) }" !! Slip,
            $node.value-attribute('caption'),
            $node.value-attribute('class'),
            $node.value-attribute('max_children'),
            $node.content_switch ?? "content_switch => { tonative($.e($node.content_switch)) }" !! Slip,
        ).join(",\n") ~ ");";

    $*CODE
}

multi method e(DTML::AST::Comment $node) {
    ''
}
