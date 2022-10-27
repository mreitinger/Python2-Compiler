import string

s = 'some string string.'
s_all = string.replace(s, 'string', 'longer string')
print s_all
s_once = string.replace(s, 'string', 'longer string', 1)
print s_once
s_empty = string.replace(s, '', 'longer string')
print s_empty
s_regex = string.replace(s, '.', 'f')
print s_regex

try:
    s_fail = string.replace(s, 0, 1)
except:
    print 'failed: old and new not of type string'

try:
    s_fail2 = string.replace(s, 'string', 'new string', 'x')
except:
    print 'failed: count must be integer'
