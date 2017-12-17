import os

with open('combineImages.sh', 'w+') as shellScript:
    shellScript.write('#!/bin/bash\n')
    for i in range(1, 35):
        if i == 21:
            continue

        sdir = '/Users/darrylhannan/SeniorProject/data/video/s' + str(i) + '/'

        shellScript.write("echo 'On s" + str(i) + "'\n")

        for directory in os.listdir(sdir):
            curdir = sdir + directory

            if not os.path.isdir(curdir):
                continue

            shellScript.write('cd ' + curdir + '\n')

            shellScript.write('mkdir unappendedFiles\n')

            fileNames = []
            for i in range(1, 76):
                fileNames.append(directory + '_' + str(i) + '.png')

            for i in range(15):
                aCommand = 'convert '
                for fileName in fileNames[5*i:5*(i+1)]:
                    aCommand += fileName + ' '
                aCommand += '+append ' + directory + 'Collection_' + str(i) +'.png\n'

                shellScript.write(aCommand)

            shellScript.write('mv ' + directory + '_*.png unappendedFiles/\n')