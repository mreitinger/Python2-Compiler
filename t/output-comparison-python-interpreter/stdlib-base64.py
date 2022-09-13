import os
import base64

# just test the callability, function is never effectively used
# base64.encode(open('/dev/null', 'r'), open('/dev/null', 'w'))
# base64.decode(open('/dev/null', 'r'), open('/dev/null', 'w'))

somestr = 'abc#.12'
enc = base64.b64encode(somestr)
print enc
print len(enc)
dec = base64.b64decode(enc)
print dec
print len(dec)



