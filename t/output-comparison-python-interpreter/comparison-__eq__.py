# Bools to whatever
a = True
b = True
c = False
print a    == a
print a    == b
print a    == c
print True == True
print True == False
print True == 1
print True == 'a'
print True == []
print True == {}

# Int to whatever
a = 1
b = 1
c = 2
print a == a
print a == b
print a == c
print 1 == True
print 1 == False
print 1 == 1
print 1 == 'a'
print 1 == []
print 1 == {}

# Str to whatever
a = 'a'
b = 'a'
c = 'b'
print a   == a
print a   == b
print a   == c
print 'a' == True
print 'a' == False
print 'a' == 1
print 'a' == 'a'
print 'a' == []
print 'a' == {}

# List to whatever
a = []
b = []
c = ['a']
print a  == a
print a  == b
print a  == c
print [] == True
print [] == False
print [] == 1
print [] == 'a'
print [] == []
print [] == {}
print c  == ['a']
print ['a', 'b'] == ['a', 'c']
print ['a', 'b'] == ['a']

# List to whatever
a = {}
b = {}
c = {'a': 'b'}
print a  == a
print a  == b
print a  == c
print {} == True
print {} == False
print {} == 1
print {} == 'a'
print {} == {}
print {} == []
print c  == {'a': 'b'}
print {'d': 'e'} == {'f': 'g'}
print {'h': 'i', 'j': 'k'} == {'l': 'm'}


