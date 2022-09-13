import os

stat = os.stat('t/testdata/stdlib-csv-test.csv')
for attr in stat:
    print attr

try:
    stat = os.stat('/non/existent/path')
except:
    print 'No such file or directory'

print os.path.exists('/foo');

os.mkdir('py2comp_test')
try:
    os.mkdir('py2comp_test')
except:
    print 'File Exists - expected'
print os.path.exists('py2comp_test')
os.rmdir('py2comp_test')

try:
    os.mkdir('/somerootdir')
except:
    print 'Permission denied - expected'
