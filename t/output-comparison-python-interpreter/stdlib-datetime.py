import datetime
import time


d = datetime.datetime(2012, 5, 12, 13, 14, 15)
format = '%Y--%m--%d %H::%M::%S'
d_formatted = d.strftime(format)
print d_formatted

d_reverse = datetime.datetime.strptime(d_formatted, format)
print d_reverse

today = datetime.datetime.today()
print today.strftime('%Y-%m-%d')

print datetime.datetime.fromtimestamp(time.time()).strftime('%Y')
print datetime.datetime.fromtimestamp(1710303166).strftime('%Y-%m-%d %H:%M:%S')

try:
    datetime.datetime()
except:
    print "TypeError: Required argument 'year' (pos 1) not found"
try:
    datetime.datetime(2012)
except:
    print "TypeError: Required argument 'month' (pos 2) not found"
try:
    datetime.datetime(2012, 5)
except:
    print "Required argument 'day' (pos 3) not found"

