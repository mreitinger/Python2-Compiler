# bax exists but is filtered, this will become a runtime error while python handles this at compile time
from Test.Module import foo
foo('passed-param 1')
baz('passed-param 2')
