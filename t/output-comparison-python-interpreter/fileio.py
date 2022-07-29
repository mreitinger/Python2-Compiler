x = open('./t/testdata/fileio-testfile.txt')
print x.read(1)
print x.read(2)
print x.read(3)
print x.read(4)
print x.read()

x.close()

try:
    x.read()
except:
    print "IO on closed filehandle failed as expected"
