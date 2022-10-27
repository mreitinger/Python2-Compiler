import string

s = 'banana bo bana bandana.'
print string.count(s, 'ana')        # => 3
print string.count(s, 'ana', 0, 21) # => 2
print string.count(s, 'ana', 4, 21) # => 1
print string.count(s, '.')          # => 1
print string.count(s, '')

try:
    print string.count(s, 'ana', 'a', 'b')
except:
    print 'failed: wrong slice parameter type'


