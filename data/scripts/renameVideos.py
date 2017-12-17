import os

with open('renameVideos.sh', 'w+') as shellScript:
    shellScript.write('#!/bin/bash\n')

    shellScript.write('cd /Users/darrylhannan/SeniorProject/data/video/finalVideos/\n')

    for file in os.listdir('/Users/darrylhannan/SeniorProject/data/video/finalVideos/'):
        if not file.endswith('.png'):
            continue

        shellScript.write('mv ' + file + ' ' + file[:file.index('_') - 10] + file[file.index('_'):] + '\n')