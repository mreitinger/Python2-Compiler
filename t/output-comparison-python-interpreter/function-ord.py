print ord('x')

try:
    print ord(1)
except TypeError:
    print "ord with int failed, as expected"

try:
    print ord('')
except TypeError:
    print "ord with empty string failed, as expected"

try:
    print ord('ab')
except TypeError:
    print "ord with more than one char failed, as expected"


try:
    print ord()
except TypeError:
    print "ord with no argument failed, as expected"
