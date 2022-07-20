class Python2::ParseFail is Exception {
    has Str $.input;
    has Int $.pos;
    has Str $.what;
}