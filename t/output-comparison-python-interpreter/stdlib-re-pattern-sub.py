import re

print re.compile(r'a').sub('b', 'faa')
print re.compile(r'^a').sub('b', 'aaa')
print re.compile(r'^a$').sub('b', 'aaa')
