import os

with open('splitVideo.sh', 'w+') as shellScript:
    shellScript.write('#!/bin/bash\n')
    for i in range(1, 35):
        if i == 21:
            continue

        curdir = '/Users/darrylhannan/SeniorProject/data/video/s' + str(i) + '/'

        shellScript.write('cd ' + curdir + '\n')

        for file in os.listdir(curdir):
            if not file.endswith('.mpg'):
                continue

            newdir = file.split('/')[-1][:-4]
            shellScript.write('mkdir ' + newdir + '\n')
            shellScript.write('cd ' + newdir + '\n')

            shellScript.write('ffmpeg -i ../' + file + ' ' + newdir + '_%d' + '.jpg\n')

            shellScript.write('cd ' + curdir + '\n')
