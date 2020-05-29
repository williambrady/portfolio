#!/usr/bin/python3
#
# Add line numbers to a CSV to emulate a database index.
###
sourcefile = 'dataset.csv'
destfile = 'indexed_dataset.csv'
log = open(destfile,"w")

with open(sourcefile) as fp:
    line = fp.readline()
    cnt = 0
    while line:
        if cnt == 0 :
            log.write ("Id,{}\n".format(line.strip()))
            print ("Id,{}".format(line.strip()))
        else:
            log.write ("{},{}\n".format(cnt, line.strip()))
            print ("{},{}".format(cnt, line.strip()))
        line = fp.readline()
        cnt += 1

log.close()
print("\nOutput file {} created.".format(destfile))

# Let's verify a valid SSH key is in place.
# grep terraform vars for ec2_keyname then verify it exists in ~/.ssh
# if not, ssh-keygen  -b 4096 and bake it in
