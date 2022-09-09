# we cannot compare shuffle as every output differs
import random

alist = ['x', random, 1, 2, {'key': 'val'}, []]
random.shuffle(alist)
print(alist)

try:
    random.shuffle({'key': 'val', 'k2': 'v2'})
except:
    print 'expecting a list'
