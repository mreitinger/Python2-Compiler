import datetime
import time

#print datetime.datetime.fromtimestamp(time.time()).strftime('%Y-%m-%d %H:%M:%S')

# always outputs current time, just checks to if don't fail and we get some sane return value
t = time.time()

if t > 1500000000 and t < 2500000000:
    print "time.time() looks sane"
