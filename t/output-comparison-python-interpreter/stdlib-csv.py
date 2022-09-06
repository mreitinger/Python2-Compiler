import csv

data = {}
r = csv.reader(open('tdata/csv/stdlib-csv-test.csv'), delimiter=';')


for row in r:
    # used several times in create_team_obj_from_file.py
    for index, item in enumerate(row):
        print item.strip()


# default separator is ','
r = csv.reader(open('tdata/csv/stdlib-csv-test-comma.csv'))

for row in r:
    print row
    print row[2]
