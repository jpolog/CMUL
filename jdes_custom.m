function [MSE,RC,SNR]=jdes_custom(fname, extension, show) 



% Open the compressed file
fid = fopen(fname,'r');
[XOR, ~, ~, ~, ~, ~, ~, TO] = imlee(archivoOrig);




% Verbosity flag
vflag = 1;
if vflag
    fprintf('Decompressing %s using custom Huffman tables...\n\n', fname);
end

% Leemos los parámetros de la imagen original
n= double(fread(fid, 1, 'uint32'));    
namp= double(fread(fid, 1, 'uint32'));  
m= double(fread(fid, 1, 'uint32'));    
mamp= double(fread(fid, 1, 'uint32'));   
caliQ= double(fread(fid, 1, 'uint32')); 

% Leemos BITS y HUFFMAN de la cabecera del fichero
% Y_DC
len_BITS_Y_DC = double(fread(fid,1,'uint32'));
BITS_Y_DC = double(fread(fid, len_BITS_Y_DC, 'uint32'));
len_HUFFVAL_Y_DC = double(fread(fid, 1, 'uint32'));
HUFFVAL_Y_DC = double(fread(fid, len_HUFFVAL_Y_DC, 'uint32'));
% Y_AC
len_BITS_Y_AC = double(fread(fid,1,'uint32'));
BITS_Y_AC = double(fread(fid, len_BITS_Y_AC, 'uint32'));
len_HUFFVAL_Y_AC = double(fread(fid, 1, 'uint32'));
HUFFVAL_Y_AC = double(fread(fid, len_HUFFVAL_Y_AC, 'uint32'));
% C_DC
len_BITS_C_DC = double(fread(fid,1,'uint32'));
BITS_C_DC = double(fread(fid, len_BITS_C_DC, 'uint32'));
len_HUFFVAL_C_DC = double(fread(fid, 1, 'uint32'));
HUFFVAL_C_DC = double(fread(fid, len_HUFFVAL_C_DC, 'uint32'));
% C_AC
len_BITS_C_AC = double(fread(fid,1,'uint32'));
BITS_C_AC = double(fread(fid, len_BITS_C_AC, 'uint32'));
len_HUFFVAL_C_AC = double(fread(fid, 1, 'uint32'));
HUFFVAL_C_AC = double(fread(fid, len_HUFFVAL_C_AC, 'uint32')); 

% Leemos los 3 canales comprimidos
% CodedY
len_sbytes_Y = double(fread(fid, 1, 'uint32'));
ultl_Y = double(fread(fid, 1, 'uint32'));
sbytes_Y = double(fread(fid, len_sbytes_Y, 'uint32'));
sbytes_Y = double(sbytes_Y);
% Obtenemos CodedY original
CodedY=bytes2bits(sbytes_Y, ultl_Y);

% CodedCb
len_sbytes_Cb = double(fread(fid, 1, 'uint32'));
ultl_Cb = double(fread(fid, 1, 'uint32'));
sbytes_Cb = fread(fid, len_sbytes_Cb, 'uint32');
sbytes_Cb = double(sbytes_Cb);
% Obtenemos CodedCb original 
CodedCb=bytes2bits(sbytes_Cb, ultl_Cb); 

% CodedCr
len_sbytes_Cr = double(fread(fid, 1, 'uint32'));
ultl_Cr = double(fread(fid, 1, 'uint32'));
sbytes_Cr = fread(fid, len_sbytes_Cr, 'uint32');
sbytes_Cr = double(sbytes_Cr);
% Obtenemos CodedCR original 
CodedCr=bytes2bits(sbytes_Cr, ultl_Cr); 
% Close the file
fclose(fid);



