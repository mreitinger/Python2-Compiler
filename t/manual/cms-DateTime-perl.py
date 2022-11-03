import DateTime

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
