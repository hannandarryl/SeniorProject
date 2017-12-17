with open('downloadVideo.sh', 'w+') as file:
	file.write('!#/bin/bash\n')
        file.write('cd ..\n')
	for i in range(1, 35):
		if i == 21:
			continue
		file.write('wget http://spandh.dcs.shef.ac.uk/gridcorpus/s' + str(i) + '/video/s' + str(i) + '.mpg_vcd.zip\n')

