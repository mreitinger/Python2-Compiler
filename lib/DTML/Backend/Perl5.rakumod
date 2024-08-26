use DTML::AST;
use Python2::Backend::Perl5;

unit class DTML::Backend::Perl5
    is Python2::Backend::Perl5;

multi method e(DTML::AST::Template $node) {
    my $body = qq:to/CODE/;
        my \$body = '';
        $node.chunks.map({self.e($_)}).join("\n")
        ;\$body;
        CODE
    sprintf(
        $.expression-wrapper,           # wrapper / sprintf definition

        '',

        # name of the class, will be Python2::Type::CodeObject::$embedded
        'main',

        'sha1_hash',   # sha1 hash for source heredoc start
        $node.input,   # python2 source code for exception handling
        'sha1_hash',   # sha1 hash for source heredoc end
        $body,         # block of main body
    );
}

multi method e(DTML::AST::Content $node) {
    if 1 < $node.content.lines {
    }
    else {
        "\$body .= '$node.content().subst("\'", "\\'")';"
    }
}

multi method e(DTML::AST::Var $node) {
    if $node.word {
        "\$body .= \$self->eval_word(\$context, \$dynamics, \\\@lexpads, '$node.word()', -1)"
    }
    else {
        "\$body .= \$\{ $.e($node.expression) \};"
    }
}

multi method e(DTML::AST::If $node) {
    my $code = "\{\n";
    $code ~= "my \$value = ";
    if $node.word {
        $code ~= "\$self->eval_word(\$context, \$dynamics, \\\@lexpads, '$node.word()', -1);\n"
    }
    else {
        $code ~= "\$\{ $.e($node.expression) \};\n"
    }
    $code ~= "if (\$value and (not ref \$value or ref \$value ne 'ARRAY' or \@\$value > 0)) \{\n";
    $code ~= $.e($_) for $node.chunks;
    $code ~= "\}\n";
    $code ~= "\}\n # /if";
}
