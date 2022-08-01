s = 'banana bo bana bandana'
print s.count('ana')        # => 3
print s.count('ana', 0, 21) # => 2
print s.count('ana', 4, 21) # => 1
print s.count('')

try:
    print s.count('ana', 'a', 'b')
except:
    print 'failed: wrong slice parameter type'


