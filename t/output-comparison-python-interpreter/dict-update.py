mydict = {'a': 'b'}
print mydict

mydict.update({ 'a': 'c' })
print mydict

mydict.update({ 'a': 'c', 'b': 'd' })
print mydict

mydict.update({ 'e': 'f' })
print mydict

# check that we return None
print mydict.update({ 'g': 'h' })
