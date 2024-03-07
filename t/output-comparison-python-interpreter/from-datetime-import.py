from datetime import datetime
d = datetime(2012, 5, 12, 13, 14, 15)
format = '%Y--%m--%d %H::%M::%S'
d_formatted = d.strftime(format)
print d_formatted
