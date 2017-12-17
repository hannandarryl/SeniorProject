import os

with open('SplitAudio.sh', 'w+') as shellScript:
    shellScript.write('#!/bin/bash\n')
    for i in range(1, 35):
        if i == 21:
            continue

        sdir = '/Users/darrylhannan/SeniorProject/data/audio/s' + str(i) + '/'

        shellScript.write("echo 'On s" + str(i) + "'\n")

        shellScript.write('cd ' + sdir + '\n')

        shellScript.write('mkdir oldAudio\n')

        for file in os.listdir(sdir):
            if not file.endswith('.wav'):
                continue

            shellScript.write('ffmpeg -i ' + file + ' -ss 0 -to 0.2 -c copy ' + file[:-4] + '_0.wav\n')
            shellScript.write('ffmpeg -i ' + file + ' -ss 0.2 -to 0.4 -c copy ' + file[:-4] + '_1.wav\n')
            shellScript.write('ffmpeg -i ' + file + ' -ss 0.4 -to 0.6 -c copy ' + file[:-4] + '_2.wav\n')
            shellScript.write('ffmpeg -i ' + file + ' -ss 0.6 -to 0.8 -c copy ' + file[:-4] + '_3.wav\n')
            shellScript.write('ffmpeg -i ' + file + ' -ss 0.8 -to 1.0 -c copy ' + file[:-4] + '_4.wav\n')
            shellScript.write('ffmpeg -i ' + file + ' -ss 1.0 -to 1.2 -c copy ' + file[:-4] + '_5.wav\n')
            shellScript.write('ffmpeg -i ' + file + ' -ss 1.2 -to 1.4 -c copy ' + file[:-4] + '_6.wav\n')
            shellScript.write('ffmpeg -i ' + file + ' -ss 1.4 -to 1.6 -c copy ' + file[:-4] + '_7.wav\n')
            shellScript.write('ffmpeg -i ' + file + ' -ss 1.6 -to 1.8 -c copy ' + file[:-4] + '_8.wav\n')
            shellScript.write('ffmpeg -i ' + file + ' -ss 1.8 -to 2.0 -c copy ' + file[:-4] + '_9.wav\n')
            shellScript.write('ffmpeg -i ' + file + ' -ss 2.0 -to 2.2 -c copy ' + file[:-4] + '_10.wav\n')
            shellScript.write('ffmpeg -i ' + file + ' -ss 2.2 -to 2.4 -c copy ' + file[:-4] + '_11.wav\n')
            shellScript.write('ffmpeg -i ' + file + ' -ss 2.4 -to 2.6 -c copy ' + file[:-4] + '_12.wav\n')
            shellScript.write('ffmpeg -i ' + file + ' -ss 2.6 -to 2.8 -c copy ' + file[:-4] + '_13.wav\n')
            shellScript.write('ffmpeg -i ' + file + ' -ss 2.8 -to 3.0 -c copy ' + file[:-4] + '_14.wav\n')

            shellScript.write('mv ' + file + ' oldAudio/\n')