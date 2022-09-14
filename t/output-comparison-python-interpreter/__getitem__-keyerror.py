x = {
    'a': {
        'b': 'c'
    }
}

try:
    print x['c']
except KeyError:
    print 'access to not existing key failed, as expected'
