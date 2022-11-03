import time
import locale
from datetime import datetime

class DateTime:
    def __init__(self, *args, **kw):
        if len(args) == 0:
            self.dt = datetime.now()
        elif len(args) == 1:
            if isinstance(args[0], (int, long, float, complex)):
                self.dt = datetime.utcfromtimestamp(args[0])
            elif isinstance(args[0], DateTime):
                self.dt = args[0].dt
            elif isinstance(args[0], basestring):
                date_string = args[0]
                if len(date_string) < 11:
                    date_string = date_string + ' 00:00:00'
                try:
                    self.dt = datetime.strptime(date_string, '%d.%m.%Y %H:%M:%S')
                except:
                    self.dt = datetime.strptime(date_string.replace('T', ' '), '%Y-%m-%d %H:%M:%S')

    def timeTime(self):
        """Return the date/time as a floating-point number in UTC,
           in the format used by the python time module."""
        return time.mktime(self.dt.timetuple())

    def toZone(self, z):
        return self

    def isPast(self):
        return self.dt < datetime.now()

    def rfc822(self): # actually it should be RFC 1123
        current_locale = locale.getlocale(locale.LC_TIME)
        locale.setlocale(locale.LC_TIME, 'en_US.UTF-8') # use english locale (rfc822 defines english day and month names)
        rfc_str = self.strftime('%a, %e %b %Y %T GMT')  # RFC 2616 requires all date fields to use "GMT" with the meaning of "UTC"
        locale.setlocale(locale.LC_TIME, current_locale)
        return rfc_str

    def strftime(self, format):
        return self.dt.strftime(format)

    def dd(self):
        return self.strftime('%m')

    def mm(self):
        return self.strftime('%m')

    def dow(self):
        return self.strftime('%w')

    def day(self):
        return int(self.strftime('%d'))

    def month(self):
        return int(self.strftime('%m'))

    def year(self):
        return int(self.strftime('%Y'))

    def __str__(self):
        return self.dt.isoformat(' ')

    def __sub__(self, d):
        if isinstance(d, DateTime):
            return self.timeTime() - d.timeTime()
        else:
            return DateTime(self.timeTime() - d)

# now
cms_dt = DateTime()

print 'isPast: %s' % cms_dt.isPast()
print 'toZone: %s' % cms_dt.toZone('GMT')
print 'rfc822: %s' % cms_dt.toZone('GMT').rfc822()
print 'timeTime: %s' % cms_dt.timeTime()
print cms_dt.strftime('%Y--%m--%d %H::%M::%S')
print cms_dt.dd()
print cms_dt.mm()
print cms_dt.dow()
print cms_dt.day()
print cms_dt.month()
print cms_dt.year()

# fixed ts
cms_dt = DateTime(1667463014)

print 'isPast: %s' % cms_dt.isPast()
print 'toZone: %s' % cms_dt.toZone('GMT')
print 'rfc822: %s' % cms_dt.toZone('GMT').rfc822()
print 'timeTime: %s' % cms_dt.timeTime()
print cms_dt.strftime('%Y--%m--%d %H::%M::%S')
print cms_dt.dd()
print cms_dt.mm()
print cms_dt.dow()
print cms_dt.day()
print cms_dt.month()
print cms_dt.year()

print DateTime() - cms_dt
print DateTime() - 1000
