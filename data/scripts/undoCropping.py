import os

with open('undoCrop.sh', 'w+') as shellScript:
    shellScript.write('#!/bin/bash\n')
    for i in range(1, 35):
        if i == 21:
            continue

        sdir = '/Users/darrylhannan/SeniorProject/data/video/s' + str(i) + '/'

        for directory in os.listdir(sdir):
            curdir = sdir + directory

            if not os.path.isdir(curdir):
                continue

            shellScript.write('cd ' + curdir + '\n')

            shellScript.write('rm *.png\n')

            shellScript.write('cd oldPhotos\n')

            shellScript.write('mv *.jpg ../\n')

            shellScript.write('cd ..\n')

            shellScript.write('rm -r oldPhotos\n')