from keras.models import Model, load_model
from keras.layers import Input, Merge, Conv2D, Conv2DTranspose, MaxPool2D, UpSampling2D, ZeroPadding2D, Dense, \
    Cropping2D, Lambda
import os
from scipy.misc import imread, imsave
import numpy as np
import matplotlib.pyplot as plt
import keras
import wave
import scipy.io.wavfile
from sklearn.preprocessing import MinMaxScaler
import keras.backend as K
import tensorflow as tf
from keras import regularizers
from keras import optimizers
from PIL import Image

inputImageEncoder = Input(shape=(48, 400, 1), name='inputImageEncoder')
inputAudioEncoder = Input(shape=(1, 10000, 1), name='inputAudioEncoder')

image = Conv2D(256, (4, 16), strides=2, activation='relu')(inputImageEncoder)
encodedImage = Conv2D(512, (22, 8), strides=2, activation='relu', name='encodedImage')(image)

audio = Conv2D(256, (1, 1000), strides=16, activation='relu')(inputAudioEncoder)
encodedAudio = Conv2D(512, (1, 8), strides=6, activation='relu', name='encodedAudio')(audio)

encoded = keras.layers.add([encodedImage, encodedAudio], name='encoded')

encoder = Model(inputs=[inputImageEncoder, inputAudioEncoder], outputs=encoded)

decoderInput = Input(shape=(1, 93, 512))
image = Conv2DTranspose(256, (22, 8), strides=(1, 2), activation='relu')(decoderInput)
decodedImage = Conv2DTranspose(1, (6, 18), strides=(2, 2), activation='relu')(image)

audio = Conv2DTranspose(256, (1, 8), strides=(1, 6), activation='relu')(decoderInput)
decodedAudio = Conv2DTranspose(1, (1, 1056), strides=(1, 16), activation='relu')(audio)

decoder = Model(inputs=decoderInput, outputs=[decodedImage, decodedAudio])

inputImage = Input(shape=(48, 400, 1))
inputAudio = Input(shape=(1, 10000, 1))

encoderOut = encoder([inputImage, inputAudio])
decoderOut = decoder(encoderOut)
autoencode = Model(inputs=[inputImage, inputAudio], outputs=decoderOut)

#def mean_squared_text(y_true, y_pred):
#    return K.mean(K.square(y_pred - y_true), axis=-1)

#def mean_squared_audio(y_true, y_pred):
#    return K.mean(K.square(y_pred - y_true), axis=-1) * 10

encoder = load_model('trainedencoder.h5')
decoder = load_model('traineddecoder.h5')
autoencode = load_model('trainedmodel.h5')

autoencode.compile(optimizer='adadelta', loss='mean_squared_error')

pngs = []
for file in os.listdir('/home/darryl/SeniorProject/data/secondaryVideo/'):
    if not file.endswith('.png'):
        continue

    img = imread('/home/darryl/SeniorProject/data/secondaryVideo/' + file)
   
    img = img.reshape((48, 400, 1))

    pngs.append(img)

freq = 0
wavs = []
for file in os.listdir('/home/darryl/SeniorProject/data/secondaryAudio/'):
    if not file.endswith('.wav'):
        continue

    wav = scipy.io.wavfile.read('/home/darryl/SeniorProject/data/secondaryAudio/' + file)

    freq = wav[0]
    wavs.append(wav[1])

wavs = np.array(wavs).astype('float32')
wavmin = np.amin(wavs)
wavmax = np.amax(wavs)

wavs = (wavs - wavmin) / (wavmax - wavmin)

wavs = [wav.reshape((1, 10000, 1)) for wav in wavs]

trainPngsX = np.array(pngs[:7500])
testPngsX = np.array(pngs[7500:])

trainPngsX = trainPngsX.astype('float32') / 255
testPngsX = testPngsX.astype('float32') / 255

trainWavsX = np.array(wavs[:7500])
testWavsX = np.array(wavs[7500:])

#autoencode.fit([trainPngsX, trainWavsX], [trainPngsX, trainWavsX], shuffle=True, verbose=2, epochs=10, batch_size=16)

#autoencode.save('trainedmodel.h5')
#encoder.save('trainedencoder.h5')
#decoder.save('traineddecoder.h5')

sparsity = encoder.predict([testPngsX, testWavsX])

testNeurons = []
for j in range(512):
    theNeuron = np.zeros((1, 95, 512))
    for i in range(95):
        theNeuron[0][i][j] = 1
    testNeurons.append(theNeuron)

testNeurons = np.array(testNeurons)

#visualization = decoder.predict(testNeurons)

decoded_imgs = autoencode.predict([testPngsX, testWavsX])

def getSparsity(sparseTensor):
    sparseCount = 0

    for matrix in sparseTensor:
        for row in matrix:
            for cell in row:
                if cell != 0:
                    sparseCount += 1

    return float(sparseCount) / sparseTensor.size * 100

sparseValues = [getSparsity(sparseValue) for sparseValue in sparsity]

avgSparsity = round(np.mean(sparseValues), 2)

print('Sparsity is: ' + str(avgSparsity) + '%')

with open('/home/darryl/SeniorProject/deepOutput/sparseValues.csv', 'w+') as file:
    file.write(str(sparseValues))

# Create a model that cuts off at the separate embeddings for each modality
activationsModel = Model(
            inputs=[encoder.get_layer('inputImageEncoder').input, encoder.get_layer('inputAudioEncoder').input],
                outputs=[encoder.get_layer('encodedImage').output, encoder.get_layer('encodedAudio').output])

# Train model and separate the output for each modality
activations = activationsModel.predict([testPngsX, testWavsX])
imageActivations = activations[0]
audioActivations = activations[1]

# Create a list of 512 lists, one for each neuron
neuronsImage = []
for x in range(512):
    neuronsImage.append([])

neuronsAudio = []
for x in range(512):
    neuronsAudio.append([])

# Sum all of the outputs for each modality to see which neurons are active
totalImageActivations = np.zeros((93, 512))
for activation in imageActivations:
    totalImageActivations = np.add(totalImageActivations, activation.reshape((93, 512)))

totalAudioActivations = np.zeros((93, 512))
for activation in audioActivations:
    totalAudioActivations = np.add(totalAudioActivations, activation.reshape((93, 512)))

def getShared(sparseTensor):
    sparseCount = 0

    for matrix in sparseTensor:
        for row in matrix:
            if row != 0:
                sparseCount += 1

    return float(sparseCount) / sparseTensor.size * 100

with open('/home/darryl/SeniorProject/deepOutput/neuronActivations.csv', 'w+') as file:
    for matrix in np.multiply(totalImageActivations, totalAudioActivations):
        for row in matrix:
            file.write(str(row) + '\n')

# See if the face and text embeddings share any neurons
print('Percentage of shared neurons is: ' + str(getShared(np.multiply(totalImageActivations, totalAudioActivations))) + '%')

for x in range(1, 95):
    imsave('/home/darryl/SeniorProject/deepOutput/' + str(x) + '_orig.png', testPngsX[x].reshape((48, 400)))
    imsave('/home/darryl/SeniorProject/deepOutput/' + str(x) + '.png', decoded_imgs[0][x].reshape((48, 400)))
    #wav3 = decoded_imgs[1][x].reshape(32768) * (wavmax-wavmin) + wavmin

    #wav3 = wav3.astype('int16')

    #scipy.io.wavfile.write('/home/darryl/SeniorProject/deepOutput/wav' + str(x) + '.wav', freq,
    #                       wav3)

    #imsave('/home/darryl/SeniorProject/deepOutput/png' + str(x) + 'Visualization.png',
    #       visualization[0][x].reshape((32, 256)))

    #wav3 = visualization[1][x].reshape(32768) * (wavmax-wavmin) + wavmin

    #wav3 = wav3.astype('int16')

    #scipy.io.wavfile.write('/home/darryl/SeniorProject/deepOutput/wav' + str(x) + 'Visualization.wav', freq,
    #                       wav3)
