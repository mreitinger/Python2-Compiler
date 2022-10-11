s = 'teststring1'
print s.endswith('1')
print s.endswith('g1')
print s.endswith(('a1', 'string1'))
print s.endswith('string1', 7)
print s.endswith('string1', 4)
print s.endswith('string1', 4, 6)
print s.endswith('st', 4, 6)

try:
   print s.endswith(3)
except:
   print 'failed: string as substring expected'

try:
   print s.endswith('la', 'x', 'y')
except:
   print 'failed: expected int as slice parameters'
