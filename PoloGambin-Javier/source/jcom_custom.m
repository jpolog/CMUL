function RC = jcom_custom(fname, caliQ)
% jcom_custom: Image compression based on custom Huffman tables
%
% Inputs:
%   fname: File name string, including suffix
%          Supports BMP and JPEG, indexed and truecolor
%   caliQ: Quality factor
%
% Outputs:
%   RC: Compression ratio
%
% Author:  Javier Polo Gambin - PCEO

% Verbosity flag
vflag = 1;
if vflag
    fprintf('--------------------------------------------------\n');
    fprintf('Funcion jcom_custom:\n');
    fprintf('Comprimiendo %s usando tablas Huffman Custom...\n\n', fname);
end

% Encoded images will be stred here
enc_filepath = './Images/encoded_custom/';  
% Generate compressed file name (.huc extension)
[~, basename, ~] = fileparts(fname);
encoded_file = strcat(enc_filepath, basename,'_Q',num2str(caliQ),'_enc_custom.huc');

% Get initial CPU time
t_ini = cputime;

%%%%%%%%%%%%%%%%%%%
% Read image file %
%%%%%%%%%%%%%%%%%%%
% Convert to YCbCr color space and expand dimensions to multiples of 8
[~, Xamp, ~, m, n, mamp, namp, TO] = imlee(fname);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute 2D DCT (blocks of 8x8 px) %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Xtrans = imdct(Xamp);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Quantize DCT coefficients %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Xlab = quantmat(Xtrans, caliQ);

%%%%%%%%%%%%%%%%%%%%%%
% Scanning & Encoding%
%%%%%%%%%%%%%%%%%%%%%%
% Scans each component (Y,Cb,Cr) separately and reorders each block in zigzag
XScan = scan(Xlab);

% Encode the three scans using custom Huffman tables
[CodedY, CodedCb, CodedCr, BITS_Y_DC, HUFFVAL_Y_DC, BITS_Y_AC, HUFFVAL_Y_AC, BITS_C_DC, HUFFVAL_C_DC, BITS_C_AC, HUFFVAL_C_AC] = EncodeScans_custom(XScan);

% Transform Scan tables to bytes and encode them
%%%%%%%% CodedY %%%%%%%%
[sbytes_Y, ultl_Y] = bits2bytes(CodedY);
% length
len_sbytes_Y = uint32(length(sbytes_Y));
% convert to int32
[sbytes_Y, ultl_Y] = deal(uint32(sbytes_Y), uint32(ultl_Y));

%%%%%%%% CodedCb %%%%%%%%
[sbytes_Cb, ultl_Cb] = bits2bytes(CodedCb);
% length
len_sbytes_Cb = uint32(length(sbytes_Cb));
% convert to int32
[sbytes_Cb, ultl_Cb] = deal(uint32(sbytes_Cb), uint32(ultl_Cb));

%%%%%%%% CodedCr %%%%%%%%
[sbytes_Cr, ultl_Cr] = bits2bytes(CodedCr);
% length
len_sbytes_Cr = uint32(length(sbytes_Cr));
% convert to int32
[sbytes_Cr, ultl_Cr] = deal(uint32(sbytes_Cr), uint32(ultl_Cr));

% We need to encode the generated BITS and HUFFVAL tables
% to store them in the compressed file (in order to decompress later)

% LUMINANCE
% Y_DC
len_BITS_Y_DC = uint32(length(BITS_Y_DC));
BITS_Y_DC = uint32(BITS_Y_DC);
len_HUFFVAL_Y_DC = uint32(length(HUFFVAL_Y_DC));
HUFFVAL_Y_DC = uint32(HUFFVAL_Y_DC);
% Y_AC
len_BITS_Y_AC = uint32(length(BITS_Y_AC));
BITS_Y_AC = uint32(BITS_Y_AC);
len_HUFFVAL_Y_AC = uint32(length(HUFFVAL_Y_AC));
HUFFVAL_Y_AC = uint32(HUFFVAL_Y_AC);

% CROMINANCE
% C_DC
len_BITS_C_DC = uint32(length(BITS_C_DC));
BITS_C_DC = uint32(BITS_C_DC);
len_HUFFVAL_C_DC = uint32(length(HUFFVAL_C_DC));
HUFFVAL_C_DC = uint32(HUFFVAL_C_DC);
% C_AC
len_BITS_C_AC = uint32(length(BITS_C_AC));
BITS_C_AC = uint32(BITS_C_AC);
len_HUFFVAL_C_AC = uint32(length(HUFFVAL_C_AC));
HUFFVAL_C_AC = uint32(HUFFVAL_C_AC);

% Encode m, n, mamp, namp, and caliQ as int32
m = uint32(m);
n = uint32(n);
mamp = uint32(mamp);
namp = uint32(namp);
caliQ = uint32(caliQ);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Write to the compressed file %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create the compressed file
fid = fopen(encoded_file, 'w');

%%% Write %%%
% Dimensions + caliQ
fwrite(fid, [m n mamp namp caliQ], 'uint32');
% Bits & Huffval encoded tables (length + value)
% Y_DC
fwrite(fid, len_BITS_Y_DC, 'uint32');
fwrite(fid, BITS_Y_DC, 'uint32');
fwrite(fid, len_HUFFVAL_Y_DC, 'uint32');
fwrite(fid, HUFFVAL_Y_DC, 'uint32');
% Y_AC
fwrite(fid, len_BITS_Y_AC, 'uint32');
fwrite(fid, BITS_Y_AC, 'uint32');
fwrite(fid, len_HUFFVAL_Y_AC, 'uint32');
fwrite(fid, HUFFVAL_Y_AC, 'uint32');
% C_DC
fwrite(fid, len_BITS_C_DC, 'uint32');
fwrite(fid, BITS_C_DC, 'uint32');
fwrite(fid, len_HUFFVAL_C_DC, 'uint32');
fwrite(fid, HUFFVAL_C_DC, 'uint32');
% C_AC
fwrite(fid, len_BITS_C_AC, 'uint32');
fwrite(fid, BITS_C_AC, 'uint32');
fwrite(fid, len_HUFFVAL_C_AC, 'uint32');
fwrite(fid, HUFFVAL_C_AC, 'uint32');

% Compressed contents of the image
% (Coded Scans of each component)
% CodedY
fwrite(fid, len_sbytes_Y, 'uint32');
fwrite(fid, sbytes_Y, 'uint32');
fwrite(fid, ultl_Y, 'uint32');

% CodedCb
fwrite(fid, len_sbytes_Cb, 'uint32');
fwrite(fid, sbytes_Cb, 'uint32');
fwrite(fid, ultl_Cb, 'uint32');

% CodedCr
fwrite(fid, len_sbytes_Cr, 'uint32');
fwrite(fid, sbytes_Cr, 'uint32');
fwrite(fid, ultl_Cr, 'uint32');

% Close file
fclose(fid);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate Compression ratio (RC) %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Header length %%%
% header = image sizes + sizes of (BITS + HUFFVAL for each luminance/crominance DC/AC)
% all data is needed for later decompression
header_len = length(n) + length(namp) + length(m) + length(mamp) + length(caliQ);
% BITS + HUFFVAL Y_DC
header_len = header_len + length(len_BITS_Y_DC) + length(BITS_Y_DC) + length(len_HUFFVAL_Y_DC) + length(HUFFVAL_Y_DC);
% BITS + HUFFVAL Y_AC
header_len = header_len + length(len_BITS_Y_AC) + length(BITS_Y_AC) + length(len_HUFFVAL_Y_AC) + length(HUFFVAL_Y_AC);
% BITS + HUFFVAL C_DC
header_len = header_len + length(len_BITS_C_DC) + length(BITS_C_DC) + length(len_HUFFVAL_C_DC) + length(HUFFVAL_C_DC);
% BITS + HUFFVAL C_AC
header_len = header_len + length(len_BITS_C_AC) + length(BITS_C_AC) + length(len_HUFFVAL_C_AC) + length(HUFFVAL_C_AC);

%%% Data length %%%
data_len = length(sbytes_Y) + length(sbytes_Cb) + length(sbytes_Cr);

%%% Compressed Size = Header + Data lengths %%%
TC = header_len + data_len;

%%%%% Compression ratio %%%%%
RC =((TO - TC)/TO)*100;


% Total CPU time
t_total = cputime - t_ini;


%%%%%%% Display information %%%%%%%
if vflag
    fprintf('Fichero comprimido generado: %s \n', encoded_file);
    fprintf('Tama�o original: %d \n', TO);
    fprintf('Tama�o comprimido: %d \n', TC);
    fprintf('RC = %f \n', RC);
    fprintf('Terminado jcom_custom\n');
    fprintf('Tiempo total CPU: %s\n', t_total);
    fprintf('--------------------------------------------------\n');
end



