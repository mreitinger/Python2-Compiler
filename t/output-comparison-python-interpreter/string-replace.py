s = 'some string string.'
s_all = s.replace('string', 'longer string')
print s_all
s_once = s.replace('string', 'longer string', 1)
print s_once
s_empty = s.replace('', 'longer string')
print s_empty
s_regex = s.replace('.', 'f')
print s_regex

try:
    s_fail = s.replace(0, 1)
except:
    print 'failed: old and new not of type string'

try:
    s_fail2 = s.replace('string', 'new string', 'x')
except:
    print 'failed: count must be integer'
