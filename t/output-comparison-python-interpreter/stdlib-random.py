import random

random.seed(5)
print random.choice(['a', 'b', 'c', 4])

print random.choice(['a', 'b', {'key': 'val'}, 4])

try:
    print random.choice({})
except:
    print 'TypeError: expected List'

try:
    print random.choice([])
except:
    print 'IndexError: list index out of range'

adict = {'x': 5, 'y': 6}
try:
    random.shuffle(adict)
except:
    print 'Cannot shuffle a dictionary'
