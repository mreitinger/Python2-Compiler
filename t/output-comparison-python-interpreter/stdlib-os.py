import os

stat = os.stat('t/testdata/stdlib-csv-test.csv')
for attr in stat:
    print attr

try:
    stat = os.stat('/non/existent/path')
except:
    print 'No such file or directory'
