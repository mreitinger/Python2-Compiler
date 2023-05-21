import string

a = "input 2 test ! string"
print string.split(a)
print string.split(a, ' ')
print string.split(a, ' ', 2)
print string.split(a, ' ', 99)
print string.split(a, '!')
print string.split(a, 'test')
print "".split(',')
