from Test.ModuleWithBody import x, z, baz

print x
print z # check for multi-target variable assignment

baz(1)

try:
    print y
    print 'access to y did not raise NameError, failure'
except NameError:
    print 'not imported variable y not found, as expected'

# check for multi-target variable assign - we did not import a
try:
    print a
    print 'access to a did not raise NameError, failure'
except NameError:
    print 'not imported variable a not found, as expected'
