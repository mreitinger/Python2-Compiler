# This is a very, very ugly hack for compatibility with ancient Zope/DTML templates.
# Some mechanism allowed strings to be accessed as a Function Call: <dtml-var "my_string()">
# This intercepts a __call__() invocation in case the string is already initialized - which
# would otherwise be interpreted as a str(whatever) call.

x = "test string"
print x()
