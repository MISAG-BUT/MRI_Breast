function appendNumbersToTxt(num1, num2, filename, txt)

    % Check if the file exists
%     if exist(filename, 'file') ~= 2
%         % Create the file with an empty array
% %         jsonStr = '[]';
%         fid = fopen(filename, 'w');
%         fwrite(fid, jsonStr);
%         fclose(fid);
%     end
    
    % Load existing JSON data
    fid = fopen(filename, 'a');
%     jsonStr = fread(fid, '*char').';
    fprintf(fid, '%s Right = %4.0f ml ; Left = %4.0f ml \n', txt, num1, num2 );
    fclose(fid);

%     data = jsondecode(jsonStr);
    
    % Append new numbers
%     newData = [data, [num1; num2]];
    
    % Write back to the JSON file
%     jsonStr = jsonencode(newData);
%     fid = fopen(filename, 'w');
%     fwrite(fid, jsonStr);
%     fclose(fid);
end
