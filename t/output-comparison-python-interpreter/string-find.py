s = 'blablablabla anchor1 anchor2 end'
print s.find('anchor1')
print s.find('anchor3')
print s.find('anchor', 20)
print s.find('anchor', 22, 31)
try:
    print s.find(3)
except:
    print 'failed: string as substring expected'



