s = 'blablablabla anchor1 anchor2 end'
print s.rfind('anchor')
print s.rfind('anchor3')
print s.rfind('anchor', 3)
print s.rfind('anchor', 3, 22)
try:
    print s.rfind(3)
except:
    print 'failed: string as substring expected'




