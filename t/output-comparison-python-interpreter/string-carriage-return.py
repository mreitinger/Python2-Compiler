print "A\rB".encode('base64')
print "C\rD".replace('\r', '').encode('base64')
