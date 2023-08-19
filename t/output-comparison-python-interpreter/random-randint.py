import random
a = 1
b = 9
rand = random.randint(1, 9)

# functionality
if a <= rand <= b:
    print "ok: random integer in expected range"
else:
    print "failure: random integer outside expected range"


# error handling
try:
    random.randint()
except TypeError:
    print "randint() without arguments failed, as expected"

try:
    random.randint(1)
except TypeError:
    print "randint() with single argument failed, as expected"

try:
    random.randint(None, 1)
except TypeError:
    print "randint() with wrong first argument failed, as expected"

try:
    random.randint(1, None)
except TypeError:
    print "randint() with wrong second argument failed, as expected"
