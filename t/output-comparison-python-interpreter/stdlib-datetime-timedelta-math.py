from datetime import timedelta

print(timedelta(1) + timedelta(2))
print(timedelta(2) - timedelta(1))

try:
    timedelta(1) + 'a'
except TypeError:
    print "timedelta addition with invalid type raises TypeError, as expected."

try:
    timedelta(1) - 'a'
except TypeError:
    print "timedelta subtraction with invalid type raises TypeError, as expected."
