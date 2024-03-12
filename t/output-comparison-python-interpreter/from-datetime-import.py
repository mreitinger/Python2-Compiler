from datetime import datetime

d = datetime(2012, 5, 12, 13, 14, 15)
format = '%Y--%m--%d %H::%M::%S'
d_formatted = d.strftime(format)
print d_formatted

print datetime.now().year
print datetime.now().month
print datetime.now().day
print datetime.now().hour
print datetime.now().minute
print datetime.now().second

try:
    datetime.now().unknown
except AttributeError:
    print("Unknown attribute for datetime.datetime raises AttributeError, as expected")

