class Python2::CompilationError is Exception {
    has Str $.error;

    method message { sprintf("%s", self.error); };
}