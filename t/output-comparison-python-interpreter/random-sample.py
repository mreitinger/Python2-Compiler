import random

x = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
print len(random.sample(x, 0))
print len(random.sample(x, 5))
print len(random.sample(x, 10))

try:
    print random.sample(x, -1)
except ValueError:
    print "Invalid sample size raised ValueError, as expected"

try:
    print random.sample(x, 15)
except ValueError:
    print "Invalid sample size raised ValueError, as expected"
