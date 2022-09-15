import re

img_attrs_spec = 'START alt="alternative text" title="title text" END'

match_obj = re.match( r'.*alt="(.+)" title="(.+)" E', img_attrs_spec)

print match_obj.group(0)
print match_obj.group(1)
print match_obj.group(2)
try:
    print match_obj.group(3)
except:
    print 'IndexError, expected'

try:
    print match_obj.group(-1)
except:
    print 'IndexError, expected'

try:
    match_obj.group('y')
except:
    print 'IndexError, expected'
