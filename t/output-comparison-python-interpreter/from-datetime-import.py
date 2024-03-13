from datetime import datetime

d = datetime(2012, 5, 12, 13, 14, 15)
format = '%Y--%m--%d %H::%M::%S'
d_formatted = d.strftime(format)
print d_formatted

d = datetime.fromtimestamp(1710303422)
print d.year
print d.month
print d.day
print d.hour
print d.minute
print d.second

try:
    datetime.now().unknown
except AttributeError:
    print("Unknown attribute for datetime.datetime raises AttributeError, as expected")

