s = "ABC"


print s[0]
print s[1]
print s[2]

try:
    print s[3]
except IndexError:
    print 'out of range (positive) returned IndexError, as expected'


print s[-0]
print s[-1]
print s[-2]
print s[-3]

try:
    print s[-4]
except IndexError:
    print 'out of range (negative) returned IndexError, as expected'
