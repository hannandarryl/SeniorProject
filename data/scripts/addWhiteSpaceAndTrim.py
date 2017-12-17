import os

with open('addWhitespace.sh', 'w+') as shellScript:
    shellScript.write('#!/bin/bash\n')

    sdir = '/home/darryl/SeniorProject/data/finalAudio/'

    shellScript.write('cd ' + sdir + '\n')

    for file in os.listdir(sdir):
        if not file.endswith('.wav'):
            continue

        shellScript.write('sox '+file+ ' '+file[:-4]+ '_pad.wav pad 0 0.2\n')
        shellScript.write('rm ' + file + '\n')
        shellScript.write('sox '+file[:-4]+ '_pad.wav '+file+ ' trim 0 0.2\n')
        shellScript.write('rm ' + file[:-4] + '_pad.wav\n')
