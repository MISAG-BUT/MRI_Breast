function [data,info] = load_raw_reg(path)

% input is file path with .mhd

fin=fopen([path]);
name = (strjoin(cellstr(char(fread(fin)))));
[~, ind2] = regexp(name,'D i m S i z e  =  ');
s = strsplit(name(ind2+1:end),'  ');
ind = regexp(s{1},' ');
s{1}(ind)='';
ind = regexp(s{2},' ');
s{2}(ind)='';
ind = regexp(s{3},' ');
s{3}(ind)='';
vel = [str2num(s{1}), str2num(s{2}), str2num(s{3})];

[~, ind2] = regexp(name,'E l e m e n t T y p e  =  ');
s = strsplit(name(ind2+1:end),'  ');
type = s{1};
type(strfind(type,' '))=[];

fclose('all');

fin=fopen([ [path(1:end-4)] '.raw']);
switch type
    case 'MET_SHORT'
        data=fread(fin,vel(1)*vel(2)*vel(3),'int16=>int16','ieee-be');
%         data=fread(fin,vel(1)*vel(2)*vel(3),'int16=>int16');
    case 'MET_USHORT'
%         data=fread(fin,vel(1)*vel(2)*vel(3),'uint16=>uint16','ieee-be');
        data=fread(fin,vel(1)*vel(2)*vel(3),'uint16=>uint16');
    case 'MET_UCHAR'
         data=fread(fin,vel(1)*vel(2)*vel(3),'uint8=>uint8','ieee-be');
%          data=fread(fin,vel(1)*vel(2)*vel(3),'uint8=>uint8');
    case 'MET_FLOAT'
        data=fread(fin,vel(1)*vel(2)*vel(3),'single=>single','ieee-be');
end
data=reshape(data,vel(1),vel(2),vel(3));
data = permute(data,[2,1,3]);
info.size = vel;
fclose('all');

[~, ind2] = regexp(name,'E l e m e n t S p a c i n g  =  ');
s = strsplit(name(ind2+1:end),'  ');
ind = regexp(s{1},' ');
s{1}(ind)='';
ind = regexp(s{2},' ');
s{2}(ind)='';
ind = regexp(s{3},' ');
s{3}(ind)='';
res = [str2num(s{1}), str2num(s{2}), str2num(s{3})];
info.resolution=res;

data = single(data);
data(data<-1026)=nan;
if nanmin(data(:))<0
    data(~isnan(data)) = data(~isnan(data))+1024;
end
data(isnan(data))=0;

switch type
    case 'MET_SHORT'
        data = int16(data);
    case 'MET_USHORT'
        data = uint16(data);
    case 'MET_UCHAR'
         data = uint8(data);
    case 'MET_FLOAT'
         data = single(data);
end


