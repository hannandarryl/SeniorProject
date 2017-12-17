function wav_to_pvp(folder, name, seconds)

   mono = true;
   dirlist = dir([folder, '/*.wav']);
   result = cell(length(dirlist), 1);
   rate = -1;
   desiredsamples = -1;
   for i = 1:length(dirlist)
      filename = dirlist(i, 1).name;
      [y, fs] = audioread([folder filename]);
      if rate == -1
         rate = fs;
         desiredsamples = seconds * rate ;
      end
      if fs ~= rate
         disp('Error: Not all files are the same bitrate. Exiting.');
         return;
      end
      channels = size(y,2);
      samples = size(y,1);
      if samples < desiredsamples
	 filename
         samples
         desiredsamples
         disp('Error: File too short. Use a smaller length.');
         return;
      end
      disp(desiredsamples);
      result{i} = struct('time', 0, 'values', []);
      if mono == true
         result{i}.values = y(1:desiredsamples, 1);
      else
         result{i}.values(1:desiredsamples,1,1) = y(1:desiredsamples, 1);
         result{i}.values(1:desiredsamples,1,2) = y(1:desiredsamples, 2);
      end
   end
   writepvpactivityfile(name, result, true);
end
