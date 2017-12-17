import os

with open('moveImages.sh', 'w+') as shellScript:
    shellScript.write('#!/bin/bash\n')
    for i in range(1, 35):
        if i == 21:
            continue

        sdir = '/Users/darrylhannan/SeniorProject/data/video/s' + str(i) + '/'

        shellScript.write("echo 'On s" + str(i) + "'\n")

        for directory in os.listdir(sdir):
            curdir = sdir + directory

            if not os.path.isdir(curdir) and not directory == 'rawVideos':
                continue

            shellScript.write('cd ' + curdir + '\n')

            fileNames = []
            for i in range(14):
                fileNames.append(directory + 'Collection_' + str(i) + '.png')

            for fileName in fileNames:
                shellScript.write('mv ' + fileName + ' /Users/darrylhannan/SeniorProject/data/video/finalVideos/\n')