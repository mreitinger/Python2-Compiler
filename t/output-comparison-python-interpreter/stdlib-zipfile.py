import zipfile
import os

with zipfile.ZipFile('test.zip', 'w') as zip_file:
    zip_file.write('t/testdata/fileio-testfile.txt', arcname='arc_fileio-testfile.txt')
    zip_file.write('t/testdata/stdlib-csv-test-comma.csv', arcname='arc_test.csv')

# not needed (already called by __exit__) but possible
zip_file.close()

# TODO: zip content does not match 100%, we don't care for now
# zip_file_read = open('test.zip')
# print zip_file_read.read().encode('base64')

with zipfile.ZipFile('test.zip') as zip_file_r:
    try:
        zip_file_r.write('t/testdata/fileio-testfile.txt', arcname='arc2_fileio-testfile.txt')
    except:
        print 'cannot write to zip opened with "r", expected'

zip_file_r.close()

os.remove('test.zip')
