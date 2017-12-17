import os

audioLocation = '/Users/darrylhannan/SeniorProject/data/audio/finalAudio/'
videoLocation = '/Users/darrylhannan/SeniorProject/data/video/finalVideos/'

audioFiles = [file for file in os.listdir(audioLocation) if file.endswith('.wav')]

videoFiles = [file for file in os.listdir(videoLocation) if file.endswith('.png')]

finalList = []
for audioFile in audioFiles:
    audioName = audioFile[:-4]
    for videoFile in videoFiles:
        videoName = videoFile[:-4]
        if audioName == videoName:
            finalList.append(audioName)
