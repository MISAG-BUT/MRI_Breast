%% mat2raw
function mat2raw_3D(Data,NewPath,Name,resolution)

mkdir(NewPath);

Data = (squeeze((Data)));
vel = size(Data);

%%%%%% ZMENIT FORMAT

I = zeros(vel,class(Data));
%%%%%%%%%%%%%%%%%%%%%%%%

I(:) = Data;
I = permute(I,[2 1 3]);

%%%%%% ZMENIT parametry
mhd = cell(13,1);
mhd{1} = 'ObjectType = Image';
mhd{2} = 'NDims = 3';
mhd{3} = 'BinaryData = True';
mhd{4} = 'BinaryDataByteOrderMSB = False';
mhd{5} = 'CompressedData = False';
mhd{6} = 'TransformMatrix = 1 0 0 0 1 0 0 0 1';
mhd{7} = 'Offset = 0 0 0';
mhd{8} = 'CenterOfRotation = 0 0 0';
mhd{9} = 'AnatomicalOrientation = RAI';
% s = num2str([0.1,0.1,0.1]);
s = num2str([resolution]);
mhd{10} = ['ElementSpacing = ' s];

datatype = class(Data);

switch datatype
    case 'uint16'
        mhd{12} = 'ElementType = MET_USHORT';  % uint16
    case 'uint8'
        mhd{12} = 'ElementType = MET_UCHAR';  % uint8
    case 'uint32'
        mhd{12} = 'ElementType = MET_UINT';  % uint32
    case 'double'
        mhd{12} = 'ElementType = MET_DOUBLE';  % double
    case 'single'
        mhd{12} = 'ElementType = MET_FLOAT';  % single
end

s = num2str([vel(2) vel(1) vel(3)]);
mhd{11} = ['DimSize = ' s];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%

mhd{13} = ['ElementDataFile = ' Name '.raw'];

fid=fopen([NewPath '\' Name '.raw'],'w+');
switch datatype
    case 'uint16'
        fwrite(fid,I,'uint16');  % uint16
    case 'uint8'
        fwrite(fid,I,'uint8');  % uint8
    case 'uint32'
        fwrite(fid,I,'uint32');  % uint32
    case 'double'
        fwrite(fid,I,'double');  % double
    case 'single'
        fwrite(fid,I,'single');  % single
end
fclose(fid);

fid=fopen([NewPath '\' Name '.mhd'],'w+');
    for ii = 1:13
        fprintf(fid,'%s\n',mhd{ii,:});
    end
fclose(fid);


