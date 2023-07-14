a = [5, 4, 1, 2, 3]
b = ['b', 'c', 'd', 'a', 'f']
c = [5, 2, 'a', 'c', 'b']

print (a, b, c)

a.sort()
b.sort()
c.sort()

print (a, b, c)

def t(b):
    return b.lower()

def test_sort(args):
    l = ['Test', 'string', 'A', 'b', 'C']

    if 'key' in args and 'reverse' in args:
        l.sort(key=args['key'], reverse=args['reverse'])
    elif 'key' in args:
        l.sort(key=args['key'])
    elif 'reverse' in args:
        l.sort(reverse=args['reverse'])
    else:
        raise Exception('invalid args to test_sort()')

    print l

test_sort({ 'key': t })
test_sort({ 'reverse': True })
test_sort({ 'reverse': False })
test_sort({ 'key': t, 'reverse': True })
test_sort({ 'key': t, 'reverse': False })
test_sort({ 'key': t, 'reverse': 0 })
test_sort({ 'key': t, 'reverse': 1 })
test_sort({ 'key': lambda s: s.lower() })

try:
    test_sort({ 'reverse': 'a' })
except TypeError:
    print("Invalid reverse parameter raises TypeError, as expected")
