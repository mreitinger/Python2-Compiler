s = 'blablablabla'
print s.startswith('bla')
print s.startswith(('la', 'bla'))
print s.startswith('la')
print s.startswith(('bla', 'la'), 1)

try:
    print s.startswith(1, 1)
except:
    print 'failed: substring must be string or tuple of strings'

try:
    print s.startswith(('la', 1))
except:
    print 'failed: found invalid tuple element (int)'

try:
   print s.startswith(3)
except:
   print 'failed: string as substring expected'

try:
   print s.startswith('la', 'x', 'y')
except:
   print 'failed: expected int as slice parameters'
