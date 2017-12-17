import os

with open('cropImages.sh', 'w+') as shellScript:
    shellScript.write('#!/bin/bash\n')
    for i in range(1, 35):
        if i == 21:
            continue

        sdir = '/Users/darrylhannan/SeniorProject/data/video/s' + str(i) + '/'

        shellScript.write("echo 'On s" + str(i) + "'\n")

        cropSize = '+120+200' # Default
        if i == 1:
            cropSize = '+120+200'
        elif i == 12:
            cropSize = '+150+180'
        elif i == 15:
            cropSize = '+135+192'
        elif i == 18:
            cropSize = '+142+192'
        elif i == 20:
            cropSize = '+155+200'
        elif i == 24:
            cropSize = '+128+202'
        elif i == 27:
            cropSize = '+140+178'
        elif i == 3:
            cropSize = '+150+187'
        elif i == 32:
            cropSize = '+140+195'
        elif i == 4:
            cropSize = '+130+190'
        elif i == 7:
            cropSize = '+135+205'
        elif i == 10:
            cropSize = '+137+202'
        elif i == 13:
            cropSize = '+147+165'
        elif i == 16:
            cropSize = '+147+175'
        elif i == 19:
            cropSize = '+140+195'
        elif i == 22:
            cropSize = '+140+227'
        elif i == 25:
            cropSize = '+135+187'
        elif i == 28:
            cropSize = '+162+185'
        elif i == 30:
            cropSize = '+150+200'
        elif i == 33:
            cropSize = '+115+190'
        elif i == 5:
            cropSize = '+135+195'
        elif i == 8:
            cropSize = '+164+167'
        elif i == 11:
            cropSize = '+140+205'
        elif i == 14:
            cropSize = '+138+188'
        elif i == 17:
            cropSize = '+140+190'
        elif i == 2:
            cropSize = '+130+187'
        elif i == 23:
            cropSize = '+152+198'
        elif i == 26:
            cropSize = '+115+170'
        elif i == 29:
            cropSize = '+137+178'
        elif i == 31:
            cropSize = '+112+178'
        elif i == 34:
            cropSize = '+152+192'
        elif i == 6:
            cropSize = '+150+180'
        elif i == 9:
            cropSize = '+130+175'


        for directory in os.listdir(sdir):
            curdir = sdir + directory

            if not os.path.isdir(curdir):
                continue

            shellScript.write('cd ' + curdir + '\n')

            shellScript.write('mkdir oldPhotos\n')

            for file in os.listdir(curdir):
                if not file.endswith('.jpg'):
                    continue

                shellScript.write('convert ' + file + ' -crop 80x48' + cropSize + ' ' + file[:-4] + '.png\n')

                shellScript.write('mv ' + file + ' oldPhotos/\n')