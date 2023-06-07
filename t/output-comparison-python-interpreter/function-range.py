try:
    print range()
except TypeError:
    print "range with 0 arguments raises TypeError, as expected"

try:
    print range([])
except TypeError:
    print "range with invalid arguments raises TypeError, as expected"

print range(-1)
print range(10)
print range(5, 10)
print range(-5, 10)
print range(-5, -10)
print range(5, 1)

