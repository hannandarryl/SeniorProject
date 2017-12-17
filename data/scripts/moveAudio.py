import os

with open('moveAudio.sh', 'w+') as shellScript:
    shellScript.write('#!/bin/bash\n')
    for i in range(1, 35):
        if i == 21:
            continue

        sdir = '/Users/darrylhannan/SeniorProject/data/audio/s' + str(i) + '/'

        shellScript.write("echo 'On s" + str(i) + "'\n")

        shellScript.write('cd ' + sdir + '\n')

        for file in os.listdir(sdir):
            if not file.endswith('.wav'):
                continue

            shellScript.write('mv ' + file + ' /Users/darrylhannan/SeniorProject/data/audio/finalAudio/\n')