import os

with open('theVideo.txt', 'w+') as output:
    for file in os.listdir('/home/darryl/SeniorProject/data/secondaryVideo/'):
        output.write('/home/darryl/SeniorProject/data/secondaryVideo/' + file + '\n')
