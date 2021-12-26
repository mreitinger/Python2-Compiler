if 1:
    print 1
    print 2

    print 3

# the empty line should have 4 spaces followed by nothing: '    \n'
if 2:
    print 4
    print 5
    
    print 6

# check to see if we loose scope (the 9 should never print since it belongs to the if block)
if 0:
    print 7
    print 8

    print 9


