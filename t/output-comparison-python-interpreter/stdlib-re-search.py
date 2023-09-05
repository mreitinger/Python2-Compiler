import re

try:
    re.search()
except TypeError:
    print 're.search without parameters raises TypeError, as expected'

try:
    re.search(1, 'foo')
except TypeError:
    print 're.search with invalid parameters (int as first) raises TypeError, as expected'

try:
    re.search('foo', 1)
except TypeError:
    print 're.search with invalid parameters (int as second) raises TypeError, as expected'

try:
    re.search('foo')
except TypeError:
    print 're.search with invalid parameters (missing second) raises TypeError, as expected'

if not re.search('does-not-exist', 'a longer string with a substring in there'):
    print 'not existing substring evaluates to false, as expected'

if re.search('substring', 'a longer string with a substring in there'):
    print 'existing substring evaluates to true, as expected'

match = re.search('(substring)', 'a longer string with a substring in there')
print match.group(0)

