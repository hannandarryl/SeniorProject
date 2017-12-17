import os

with open('convertGreyscale.sh', 'w+') as file:
    file.write('#!/bin/bash\n')

    for videoFile in os.listdir('/home/darryl/SeniorProject/data/secondaryVideo/'):
        if not videoFile.endswith('.png'):
            continue

        file.write('convert ~/SeniorProject/data/secondaryVideo/' + videoFile + ' -colorspace Gray ~/SeniorProject/data/secondaryVideo/' + videoFile + '\n')
