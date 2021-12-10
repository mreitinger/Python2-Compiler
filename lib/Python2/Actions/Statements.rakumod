use Python2::AST;
use Data::Dump;

class Python2::Actions::Statements {
    multi method statement($/ where $<expression>) {
        $/.make($<expression>.made);
    }

    multi method statement($/ where $<statement-print>) {
        $/.make($<statement-print>.made);
    }

    multi method statement-print($/) {
        $/.make(Python2::AST::Node::Statement::Print.new(
            expression => $/<expression>.made
        ));
    }

    multi method statement ($/) {
        die("Action for statement not implemented: " ~ $/)
    }
}