import re

x = 'a b c A B C'
y = [1, 2, 3, 4]

r = re.compile('[a]')

if r.match(x):
    print 'matched 1'

try:
    if r.match(y):
        print 'matched 2 - failed'
except TypeError:
    print "match against invalid object failed, as expected"
