class Python2::AST {
    class Type {
    }
    class PerlObject is Type {
        method method-known($name) {
            False
        }
    }
    class ZMSObject is PerlObject {
        my $known-methods = set <
            instance
            meta_object
            object_attrs
            object_attrs_hash
            initialize_all_attributes
            set_default_values
            augment_with_default_values
            copy
            cache
            request_caching
            eq
            refresh
            clean_request_caches
            embedded_with_parent
            is_trashcan
            in_trashcan
            get_body_content
            get_child_nodes
            get_obj_children
            get_child_by_id
            get_decl_id
            get_content_file_name
            generate_dcid
            has_page_elements
            first_page_child
            get_page_with_elements
            get_path
            get_uri
            absolute_url
            absolute_url_path
            get_decl_uri
            get_decl_page_uri
            get_href_to_index_html
            get_href_to_index_pdf
            get_href_to_app_html
            get_href
            get_static_uri
            get_static_path
            get_parent_node
            get_prev_sibling
            get_next_sibling
            get_level
            get_parent_by_level
            is_page
            is_page_element
            get_page
            get_property
            set_property
            get_document_element
            get_link
            get_caption
            get_link_caption
            get_management_uri
            get_profiler_uri
            get_properties_uri
            get_after_save_properties_uri
            get_management_interface
            get_edit_form
            bb_meta_information
            get_dynamic_fields
            get_icon_url
            is_content_imported_folder
            get_last_modified_datetime
            update_from_data
            pre_write
            post_write
            validate
            insert
            update
            delete
            linked_in_uid_attributes
            move_after
            move_to_parent
            copy_to_parent
            copy_children
            prefix_for_copy
            create_child
            id_prefix
            in_parents
            get_files
            prepare_files
            store_files
            delete_files
            copy_files
            clear_attribute
            get_dirty_columns
            get_parents
            get_static_parents
            get_meta_type_desc
            get_meta_type
            get_std_attrs
            get_obj_by_path
            get_attr_spec
            resolve_attr_uri
            roles
            object_roles
            resolve_roles
            user_has_role
            restricted_parents
            user_has_access
            id_quote
            url_quote
            is_active
            toggle_active
            is_translated
            is_visible
            document_unique_id
            thumbnail
            is_attribute
            get_link_url
            get_description
            get_inline_svg
            get_uid
            url_append_params
            get_static_file_uri
            search_quote
            breadcrumbs_obj_path
            exec_dtml
            exec_python
            exec_plugin_atikon
            search
            children
            descendants
            changed_tree
            log_info
            ancestor_has_property
            getParentNode
            getParentByLevel
            getChildNodes
            objectValues
            getDocumentElement
            getHref2IndexHtml
            getHref2IndexPdf
            getHref2SitemapHtml
            getHref2PrintHtml
            getDeclUrl
            getDeclId
            getObjProperty
            setObjProperty
            getObjChildren
            getBodyContent
            bodyContent_Float
            renderShort
            getLinkUrl
            getLinkObj
            isActive
            isVisible
            isMetaType
            isPage
            isPageElement
            isResource
            getId
            getLevel
            getSelf
            getPrimaryLanguage
            getLanguageLabel
            getLangStr
            getLanguages
            getLanguage
            isTranslated
            getLangFmtDate
            parseLangFmtDate
            hasAccess
            ImageUtils_getThumbnail
            replace_email
            protectEmail
            HP_URL
            is_robot
            bobobase_modification_time
            getHome
            __getattr__
            __getitem__
            __cmp__
            >;
        method method-known($name) {
            $known-methods{$name}:exists
        }
    }
    class ReturnsZMSObject is Type {
    }
    class ZMSObjectArray is Type {
    }
    class Request is PerlObject {
        my $known-methods = set <
                __getitem__
                __str__
                __getattr__
                __hasattr__
                __setitem__
                get
                set
                has_key
                get_rendered_content
                dump_debug_information
                response
                is_robot
                get_vars
                get_upload
                stash
                clean
                management_interface
                management_saved
                address
                user
                cookies
            >;
        method method-known($name) {
            $known-methods{$name}:exists
        }
    }

    # base node type, keeps track of where in the source code the node was defined
    class Node {
        # position in the original python file
        has $.start-position = Nil;       # TODO mark as required once we support it everywhere
        has $.end-position   = Nil;       # TODO mark as required once we support it everywhere
        has Type $.type is rw; # Propagates bottom up
        has Type $.context is rw; # Propagates top down
        method calculate-type(Type $context) {
            Type
        }
        method calculate-context(Type $context --> Type) {
            $.context = $context;
        }
        method calculate-types(Type $context?) {
            self.calculate-context($context);
            for self.^attributes {
                if $_.type ~~ Node {
                    .calculate-types($.context) with .get_value(self);
                }
                elsif .type ~~ Positional[Node] {
                    for .get_value(self) {
                        .calculate-types($context) if .defined;
                    }
                }
            }
            self.calculate-type($context);
        }
    }

    role Statement { } # Marker role for all statements
    role Declaration {
        method decls(--> Iterable) { ... }
    } # Marker role for all declarations

    class Node::Statement is Node {
        has Node $.statement is required is rw;

        method walk-statements(&code) {
            my $recurse = &code(self.statement);
            if $recurse and self.statement.^can('walk-statements') {
                self.statement.walk-statements(&code)
            }
        }
    }

    class Node::Statement::VariableAssignment { ... }

    role LexicalScope {
        method declarations() {
            my @decls;
            self.block.walk-statements(-> $node {
                if $node ~~ Node::Statement {
                    True
                }
                elsif $node ~~ Statement {
                    @decls.push: $node if $node ~~ Declaration;
                    $node !~~ LexicalScope
                }
                else { # Only statements can hold declarations that we're interested in (i.e. not in lambdas)
                    False
                }
            });
            @decls;
        }
    }

    role BlockOwner {
        method walk-statements(&code) {
            self.block.walk-statements(&code);
        }
    }

    class Node::Block is Node {
        has Node @.statements is rw;

        method walk-statements(&code) {
            for @.statements {
                my $recurse = &code($_);
                if $recurse and $_.^can('walk-statements') {
                    $_.walk-statements(&code)
                }
            }
        }
    }

    # top level node
    class Node::RootBlock is Node::Block does LexicalScope {
        has Str  $.input is required;

        method block { self }
    }

    # top level node for expressions
    class Node::RootExpression is Node {
        has Node @.nodes is rw;
        has Str  $.input is required;
    }

    class Node::Expression is Node {}

    class Node::Name is Node {
        has Str $.name is required is rw;
        # unless this is False we check if it
        # resolves at runtime. this is overridden only by VariableAssignment.
        # even if false everything but the last element (atom and/or trailers) must resolve.
        has Bool $.must-resolve is rw = True;
    }

    class Node::Power is Node {
        has Node $.atom     is required is rw;
        has Node @.trailers is required is rw;
    }

    class Node::Atom is Node {
        # if this is false we don't recurse upwards on the stack
        # this is overridden only by VariableAssignment otherwise we would overwrite variables
        # outside of our scope
        has Bool $.recurse      is rw = True;

        has Node $.expression is required is rw;

        method calculate-type($context) {
            $.context = $context;
            if self.expression ~~ Node::Name {
                if self.expression.name eq 'this' {
                    $.type = ReturnsZMSObject;
                }
                elsif self.expression.name eq 'REQUEST' {
                    $.type = Request;
                }
            }
        }
    }

    class Node::ArgumentList is Node {
        has Node @.arguments is required is rw;
        has Node $.flattened-nameds is rw;
    }


    # expressions
    class Node::Expression::Container is Node {
        # list of bitwise expressions
        has Node @.expressions   is required is rw;

        # list bitwise operators (between the expressions)
        has Str  @.operators     is required is rw;
    }

    class Node::Expression::Literal::String is Node {
        has Str     $.value     is required  is rw;
        has Bool    $.raw       is required;
        has Bool    $.unicode   is required;
    }

    class Node::Expression::Literal::Integer is Node {
        has Int $.value is required  is rw;
    }

    class Node::Expression::Literal::Float is Node {
        has Num $.value is required  is rw;
    }

    class Node::Expression::VariableAccess is Node {
        has Node $.name is required is rw;
    }

    class Node::Expression::ArithmeticOperator is Node {
        has Str $.arithmetic-operator is required  is rw;
    }

    class Node::Expression::ArithmeticExpression is Node {
        has Node @.operations is required is rw;
    }

    class Node::Expression::InstanceVariableAccess is Node {
        has Node $.name is required is rw;
    }

    class Node::Subscript is Node {
        has Node $.value    is required is rw;
        has Node $.target   is rw; # for array slicing
    }

    class Node::Expression::ListDefinition is Node {
        has Node @.expressions is rw;
    }

    class Node::Expression::ExpressionList is Node {
        has Node @.expressions is rw;
    }

    class Node::Expression::TestList is Node {
        has Node @.tests is rw;
        has Bool $.trailing-comma is rw;

        method calculate-type($context) {
            $.context = $context;
            if self.tests.elems == 1 {
                $.type = self.tests[0].type;
            }
        }
    }

    class Node::Expression::DictionaryDefinition is Node {
        has Pair @.entries is required is rw;
    }

    class Node::DictComprehension is Node {
        has Node    @.names         is required is rw;
        has Node    $.iterable      is required is rw;
        has Node    $.key           is required is rw;
        has Node    $.value         is required is rw;
        has Node    $.condition     is rw;
    }

    class Node::Expression::SetDefinition is Node {
        has Node @.entries is required is rw;
    }

    class Node::Locals is Node {}


    # Statements
    class Node::Statement::Pass is Node does Statement {}

    class Node::Statement::P5Import is Node does Statement {
        has Str $.perl5-package-name is required  is rw;
        has Str $.name is required  is rw;
    }

    class Node::Statement::Import is Node does Statement {
        has @.modules is required  is rw;
    }

    class Node::Statement::FromImport is Node does Statement {
        has Str  $.name is required  is rw;
        has Str  $.name-as is required  is rw;
        has Node $.import-names is required is rw;
    }

    class Node::Statement::ImportNames is Node does Statement {
        has Node @.names is required is rw;
    }

    class Node::Test is Node {
        has Node $.condition    is required is rw;
        has Node $.left         is required is rw;
        has Node $.right        is required is rw;
    }

    class Node::Test::Logical is Node {
        has Node $.condition    is required is rw;
        has Node @.values       is rw is required;
    }

    class Node::Test::LogicalCondition is Node {
        has Str $.condition    is required is rw;
    }

    class Node::Statement::Print is Node does Statement {
        has @.values is required is rw;
    }

    class Node::Statement::Continue is Node does Statement {}

    class Node::Statement::Del is Node does Statement {
        has Node $.name is required is rw;
    }

    class Node::Statement::Assert is Node does Statement {
        has Node $.assertion is required is rw;
        has Node $.message is rw;
    }

    class Node::Statement::Raise is Node does Statement {
        has Node $.exception is required is rw;
        has Node $.message   is rw;
    }

    class Node::Statement::VariableAssignment is Node does Statement does Declaration {
        has Python2::AST::Node @.targets       is required is rw;
        has                    @.name-filter;
        has Node               $.expression    is required is rw;

        method decls(--> Iterable) {
            @.targets.grep({$_ ~~ Python2::AST::Node::Atom and $_.expression ~~ Python2::AST::Node::Name}).map(*.expression)
        }
    }

    class Node::Statement::ArithmeticAssignment is Node does Statement {
        has Node    $.target    is required is rw;
        has Node    $.value     is required is rw;
        has Str     $.operator  is required;
    }

    class Node::Statement::LoopFor is Node does BlockOwner does Statement does Declaration {
        has Node    @.names         is required is rw;
        has Node    $.iterable      is required is rw;
        has Node    $.block         is required is rw;

        method decls(--> Iterable) {
            @.names
        }
    }

    class Node::Statement::LoopWhile is Node does BlockOwner does Statement {
        has Node    $.test          is required is rw;
        has Node    $.block         is required is rw;
    }

    class Node::ListComprehension is Node {
        has Node    $.name          is required is rw;
        has Node    $.iterable      is required is rw;
        has Node    $.test          is required is rw;
        has Node    $.condition     is rw;
    }

    class Node::Statement::If is Node does BlockOwner does Statement {
        has Node    $.test  is required is rw;
        has Node    $.block is required is rw;
        has Node    @.elifs is rw; #optional else-if blocks
        has Node    $.else  is rw;

        method walk-statements(&code) {
            self.block.walk-statements(&code);
            $_.walk-statements(&code) for @.elifs;
            $_.walk-statements(&code) with self.else;
        }
    }

    class Node::Statement::With is Node does BlockOwner does Statement {
        has Node    $.test  is required is rw;
        has Node    $.block is required is rw;
        has Node    $.name  is required is rw;
    }

    class Node::Statement::ElIf is Node does BlockOwner does Statement {
        has Node    $.test  is required is rw;
        has Node    $.block is required is rw;
    }

    class Node::Statement::TryExcept is Node does Statement {
        has Node    $.try-block  is required is rw;
        has Node    @.except-blocks is required is rw;
        has Node    $.finally-block is rw;

        method walk-statements(&code) {
            $.try-block.walk-statements(&code);
            $_.walk-statements(&code) for @.except-blocks;
            $_.walk-statements(&code) with $.finally-block;
        }
    }

    class Node::ExceptionClause is Node does BlockOwner {
        has Node $.exception is rw; # exception where this block is relevant, optional for plain 'except:'
        has Node $.name  is rw; # name of the variable where we assign the exception to
        has Node $.block is required is rw;
    }

    class Node::Statement::Test::Expression is Node does Statement {
        has Node $.expression  is required is rw;
    }

    class Node::Statement::Return is Node does Statement {
        has Node $.value is rw;
    }

    class Node::Statement::Break is Node does Statement {}

    class Node::Statement::Test::Comparison is Node does Statement {
        has Node @.operands is required is rw;
        has Str @.operators is required is rw;
    }

    class Node::Statement::FunctionDefinition is Node does BlockOwner does LexicalScope does Statement does Declaration {
        has Node    $.name is required is rw;
        has Node    @.argument-list is required is rw;
        has Node    $.block is required is rw;

        method decls(--> Iterable) {
            ($!name,)
        }
    }

    class Node::Statement::FunctionDefinition::Argument is Node does Statement {
        has Node    $.name is required is rw;
        has Node    $.default-value is rw;
        has Int     $.splat = 0;
    }

    class Node::Argument is Node {
        has Node    $.value is required;
        has Node    $.name; #optional: could be a named argument
        has Bool    $.splat;
    }

    class Node::LambdaDefinition is Node is LexicalScope {
        has Node    @.argument-list is required  is rw;
        has Node    $.block is required is rw;
    }

    class Node::Statement::ClassDefinition is Node does BlockOwner does LexicalScope does Statement does Declaration {
        has Node    $.name          is required is rw;
        has Node    $.block         is required is rw;
        has Node    $.base-class;

        method decls(--> Iterable) {
            ($!name,)
        }
    }

    class Node::PropertyAccess is Node {
        has Node $.atom           is required is rw;
        has Node::Name $.property is required;
    }

    class Node::SubscriptAccess is Node {
        has Bool $.must-resolve is rw = True;
        has Node            $.atom      is required is rw;
        has Node::Subscript $.subscript is required;
    }

    class Node::Call is Node {
        has Node               $.atom    is required;
        has Node::ArgumentList $.arglist is required;
    }

    class Node::Call::Name is Node {
        has Node::Atom         $.name    is required;
        has Node::ArgumentList $.arglist is required;

        method calculate-type($context) {

            if not self.arglist.arguments and self.name.type ~~ Python2::AST::ReturnsZMSObject {
                $.type = ZMSObject;
            }
        }
    }

    class Node::Call::Method is Node {
        has Node               $.atom    is required is rw;
        has Node::Name         $.name    is required;
        has Node::ArgumentList $.arglist is required;
    }

    class Node::Comment is Node {
        has Str $.comment is required is rw;
    }
}
