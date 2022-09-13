print float('300.44') * 10
print float('.44789') * 0.1
try:
    print float('.abc')
except:
    print 'ValueError: invalid literal for float'
try:
    print float('300,44')
except:
    print 'ValueError: invalid literal for float'
try:
    print float('asdf')
except:
    print 'ValueError: invalid literal for float'
