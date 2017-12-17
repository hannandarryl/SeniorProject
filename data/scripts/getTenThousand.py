import os
import random

with open('getTenThousand.sh', 'w+') as script:

    allFileNames = {file[:-4] for file in os.listdir('/home/darryl/SeniorProject/data/finalAudio') if file.endswith('.wav')} & {file[:-4] for file in os.listdir('/home/darryl/SeniorProject/data/finalVideos') if file.endswith('.png')}

    fileList = list(allFileNames)

    random.shuffle(fileList)

    for i in range(10000):
        thefile = fileList[i]
        print(thefile)
        script.write('cp /home/darryl/SeniorProject/data/finalAudio/' + thefile + '.wav /home/darryl/SeniorProject/data/secondaryAudio/\n')
        script.write('cp /home/darryl/SeniorProject/data/finalVideos/' + thefile + '.png /home/darryl/SeniorProject/data/secondaryVideo/\n')
