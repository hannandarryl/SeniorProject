import os

listOfAudio = {file[:-4] for file in os.listdir('../finalAudio/') if file.endswith('.wav')}

listOfVideo = {file[:-4] for file in os.listdir('../finalVideos/') if file.endswith('.png')}

finalSetOfFiles = listOfAudio & listOfVideo

with open('/home/darryl/SeniorProject/audioFiles.txt', 'w+') as audioFile:
    with open('/home/darryl/SeniorProject/videoFiles.txt', 'w+') as videoFile:
        for fileName in finalSetOfFiles:
            audioFile.write(fileName + '.wav\n')
            videoFile.write(fileName + '.png\n')
