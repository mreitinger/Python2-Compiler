string = 'abc123._#'

print string.encode('utf8')
print string.encode('utf-8')
try:
    print string.encode('foo')
except:
    print 'LookupError: unknown encoding: foo'
enc = string.encode('base64')
print enc
dec = enc.decode('base64')
print dec




