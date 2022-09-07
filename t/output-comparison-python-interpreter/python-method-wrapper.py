# See PythonMethod.pm for details

import re

x = 'a b c A B C'

r = re.compile('[a]').match

if r(x):
    print 'matched 1'
else:
    print 'match failed'
