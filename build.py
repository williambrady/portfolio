#!/usr/bin/python3
"""
Open the initial CSV file and add row numbers to emulate an index.
This will allow AWS S3 Select to query the file directly instead of requiring a database.
This loader will also package the lambda function for inclusion in the S3 upload.
"""
import sys
import subprocess

sourcefile = "{}".format(sys.argv[1])
#sourcefile = 'dataset.csv'
destfile = 'indexed_dataset.csv'
log = open(destfile,"w")

print("Creating an indexed version of the original data.")
with open(sourcefile) as fp:
    line = fp.readline()
    cnt = 0
    while line:
        if cnt == 0 :
            log.write ("carId,{}\n".format(line.strip()))
            # print ("carId,{}".format(line.strip()))
        else:
            log.write ("{},{}\n".format(cnt, line.strip()))
            # print ("{},{}".format(cnt, line.strip()))
        line = fp.readline()
        cnt += 1

log.close()
print("Output file {} created.".format(destfile))

"""
Lambda Packager: zip the python file into a zip with no path included.
This is required for successful Lambda inclusion.
"""

ZIP = subprocess.check_output("zip -j lambda_function.zip lambda_function.py",shell=True).strip()
ZIP = ZIP.decode().strip()
print("Zipping lambda function: {}".format(ZIP))
print("") # Adding a trailing \n for asthetics
