with open('./t/testdata/fileio-testfile.txt') as x:
    print x.read(1)
    print x.read(2)
    print x.read(3)
    print x.read(4)
    print x.read()

try:
    x.read()
except:
    print "filehandle was closed after with block executed, as expected"
