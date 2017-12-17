addpath('~/OpenPV/mlab/util/');

Fs = 10000;

filename = '~/SeniorProject/output/InputAudioRecon.pvp'
data = readpvpfile(filename);

windowsize = length(data{1}.values)
numwindows = length(data)

outwave=[];
for n = 1:2
% 
     %newn = n*windowsize
     %newn = 1;
     %outwav(newn:newn+windowsize-1) = data{n}.values / (max(data{n}.values));
     if (max(data{n}.values) > 0)
         outwave = [outwave; data{n}.values/(max(data{n}.values))];
     endif
 end
%outwav = data{1}.values / (max(data{1}.values));

audiowrite('recon.wav',outwave,Fs);
