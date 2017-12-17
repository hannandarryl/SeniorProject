with open('downloadAlign.sh', 'w+') as file:
	file.write('!#/bin/bash\n')
	for i in range(1, 35):
		if i == 21:
			continue
		file.write('wget http://spandh.dcs.shef.ac.uk/gridcorpus/s' + str(i) + '/align/s' + str(i) + '.tar\n')

