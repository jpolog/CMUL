function RC = jcom_custom(fname,caliQ,extension)

% jcom_custom: Compresion de imágenes basada en las tablas customizadas

% Entradas:
%  fname: Un string con nombre de archivo, incluido sufijo
%         Admite BMP y JPEG, indexado y truecolor
%  caliQ: Factor de calidad (entero positivo >= 1)
%         100: calidad estandar
%         >100: menor calidad
%         <100: mayor calidad
%  extension: String que indica la extensión del archivo, en mi caso bmp o
%  png
% Salidas:
%  RC: Relacion de compresion


% Verbosity flag
vflag = 1;
if vflag
    % Display function name
    fprintf('Compressing %s using custom Huffman compression...\n\n', fname);
end

% Get initial time
t_ini=cputime;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read image file and convert to YCbCr color space %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Expand dimensions to multiples of 8
[~, Xamp, ~, m, n, mamp, namp, TO]=imlee(fname);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute 2D DCT (blocks of 8x8 px) %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Xtrans = perform_dct(Xamp);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Quantize DCT coefficients %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Xlab=quantmat(Xtrans, caliQ);


%%%%%%%%%%%%%%%%%%%%%%
% Scanning & Encoding%
%%%%%%%%%%%%%%%%%%%%%%
% Scan each color component separately and reorder each block in zigzag
% (each scan is an mamp x namp matrix)
XScan=scan(Xlab);

% Encode the three scans using custom Huffman tables
[CodedY, CodedCb, CodedCr,BITS_Y_DC, HUFFVAL_Y_DC, BITS_Y_AC, HUFFVAL_Y_AC, BITS_C_DC,HUFFVAL_C_DC, BITS_C_AC, HUFFVAL_C_AC] = EncodeScans_custom(XScan);

% Transform obtained Scans tables to bytes and encode them
%%%%%%%% CodedY %%%%%%%%
[sbytes_Y, ultl_Y]=bits2bytes(CodedY);
% length
len_sbytes_Y=uint32(length(sbytes_Y));
%convert to int32
[sbytes_Y, ultl_Y] = deal(uint32(sbytes_Y), uint32(ultl_Y));

%%%%%%%% CodedCb %%%%%%%%
[sbytes_Cb, ultl_Cb]=bits2bytes(CodedCb);
% length
len_sbytes_Cb=uint32(length(sbytes_Cb));
% convert to int32
[sbytes_Cb, ultl_Cb] = deal(uint32(sbytes_Cb), uint32(ultl_Cb));

%%%%%%%% CodedCr %%%%%%%%
[sbytes_Cr, ultl_Cr]=bits2bytes(CodedCr);
% length
len_sbytes_Cr=uint32(length(sbytes_Cr));
% convert to int32
[sbytes_Cr, ultl_Cr] = deal(uint32(sbytes_Cr), uint32(ultl_Cr));


% We need to encode the generated Bits and Huffval tables too
% to store them in the compressed file 
% LUMINANCE
% Y_DC
len_BITS_Y_DC=uint32(length(BITS_Y_DC)); 
BITS_Y_DC=uint32(BITS_Y_DC); 
len_HUFFVAL_Y_DC=uint32(length(HUFFVAL_Y_DC));
HUFFVAL_Y_DC=uint32(HUFFVAL_Y_DC); 
% Y_AC
len_BITS_Y_AC=uint32(length(BITS_Y_AC)); 
BITS_Y_AC=uint32(BITS_Y_AC); 
len_HUFFVAL_Y_AC=uint32(length(HUFFVAL_Y_AC));
HUFFVAL_Y_AC=uint32(HUFFVAL_Y_AC); 

% CROMINANCE
% C_DC
len_BITS_C_DC=uint32(length(BITS_C_DC)); 
BITS_C_DC=uint32(BITS_C_DC); 
len_HUFFVAL_C_DC=uint32(length(HUFFVAL_C_DC));
HUFFVAL_C_DC=uint32(HUFFVAL_C_DC); 
% C_AC
len_BITS_C_AC=uint32(length(BITS_C_AC)); 
BITS_C_AC=uint32(BITS_C_AC); 
len_HUFFVAL_C_AC=uint32(length(HUFFVAL_C_AC));
HUFFVAL_C_AC=uint32(HUFFVAL_C_AC); 


% Encode m, n, mamp, namp and caliQ as int32
m=uint32(m);
mamp=uint32(mamp);
n=uint32(n);
namp=uint32(namp);
caliQ=uint32(caliQ);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Write to the compressed file %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Generate compressed file name (.hud extension)
[~,name,~] = fileparts(fname);
compressed_filename = strcat(name, '.hud');

% Create the compressed file
fid = fopen(compressed_filename,'w');

%%% Write %%%
% Dimensions + caliQ
fwrite(fid,n,'uint32');
fwrite(fid,namp,'uint32');
fwrite(fid,m,'uint32');
fwrite(fid,mamp,'uint32');
fwrite(fid,caliQ,'uint32');
% Bits & Huffval encoded tables
% Y_DC
fwrite(fid,len_BITS_Y_DC,'uint32'); 
fwrite(fid,BITS_Y_DC,'uint32'); 
fwrite(fid,len_HUFFVAL_Y_DC,'uint32'); 
fwrite(fid,HUFFVAL_Y_DC,'uint32');
% Y_AC
fwrite(fid,len_BITS_Y_AC,'uint32'); 
fwrite(fid,BITS_Y_AC,'uint32'); 
fwrite(fid,len_HUFFVAL_Y_AC,'uint32'); 
fwrite(fid,HUFFVAL_Y_AC,'uint32');
% C_DC
fwrite(fid,len_BITS_C_DC,'uint32'); 
fwrite(fid,BITS_C_DC,'uint32'); 
fwrite(fid,len_HUFFVAL_C_DC,'uint32'); 
fwrite(fid,HUFFVAL_C_DC,'uint32');
% C_AC
fwrite(fid,len_BITS_C_AC,'uint32'); 
fwrite(fid,BITS_C_AC,'uint32'); 
fwrite(fid,len_HUFFVAL_C_AC,'uint32'); 
fwrite(fid,HUFFVAL_C_AC,'uint32');

% Now the coded Scans
% CodedY
fwrite(fid,len_sbytes_Y,'uint32');
fwrite(fid,ultl_Y,'uint32');
fwrite(fid,sbytes_Y,'uint32');
% CodedCb
fwrite(fid,len_sbytes_Cb,'uint32'); 
fwrite(fid,ultl_Cb,'uint32'); 
fwrite(fid,sbytes_Cb,'uint32'); 
% CodedCr
fwrite(fid,len_sbytes_Cr,'uint32'); 
fwrite(fid,ultl_Cr,'uint32'); 
fwrite(fid,sbytes_Cr,'uint32'); 
% Close file
fclose(fid);

% RC is calculated
% header = image sizes + sizes of(BITS + HUFFVAL for each luminance/crominance DC/AC)
% all data is needed for later decompression
%image sizes
header_len = length(n)+length(namp)+length(m)+length(mamp)+length(caliQ);
% BITS + HUFFVAL Y_DC
header_len = header_len+length(len_BITS_Y_DC)+length(BITS_Y_DC)+length(len_HUFFVAL_Y_DC)+length(HUFFVAL_Y_DC);
% BITS + HUFFVAL Y_AC
header_len = header_len+length(len_BITS_Y_AC)+length(BITS_Y_AC)+length(len_HUFFVAL_Y_AC)+length(HUFFVAL_Y_AC);
% BITS + HUFFVAL C_DC
header_len = header_len+length(len_BITS_C_DC)+length(BITS_C_DC)+length(len_HUFFVAL_C_DC)+length(HUFFVAL_C_DC);
% BITS + HUFFVAL C_AC
header_len = header_len+length(len_BITS_C_AC)+length(BITS_C_AC)+length(len_HUFFVAL_C_AC)+length(HUFFVAL_C_AC);
% Data
data_len=length(sbytes_Y)+ length(sbytes_Cb)+length(sbytes_Cr);
TC = header_len + data_len;
RC = 100* ((TO-TC)/TO);

% Total time
t_total = cputime - t_ini;

% Display information
if vflag
    fprintf('Total CPU Time: %s\n', t_total);
    fprintf('Obtained compressed file: %s \n', compressed_filename);
    fprintf('Original size: %d \n', TO);
    fprintf('Compressed size: %d \n', TC);
    fprintf('RC = %f \n', RC);
    fprintf('Finished Default Huffman Compression\n\n');
end
