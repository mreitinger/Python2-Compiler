x = "a|b|c|d"
print x.rsplit('|')
print x.rsplit('|', 2)
print x.rsplit('|', 0)
print x.rsplit('|', -1)
print x.rsplit('|', -5)

test = '12345'
test = str(test.rsplit('123'))
print test
