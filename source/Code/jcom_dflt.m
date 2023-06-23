function RC = jcom_dflt(fname, caliQ)
% jcom_dflt: Image compression based on default Huffman tables
%
% Inputs:
%   fname: String containing the file name, including suffix
%          Accepts BMP and JPEG, indexed and truecolor
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
    fprintf('Funcion jcom_dflt:\n');
    fprintf('Comprimiendo %s usando tablas Huffman Default...\n', fname);
end

% Encoded images will be sotred here
enc_filepath = '../Images/encoded_dflt/';  
% Generate compressed file name (.hud extension)
[~, basename, ~] = fileparts(fname);
encoded_file = strcat(enc_filepath, basename,'_Q',num2str(caliQ),'_enc_dflt.hud');

% Get initial time
t_ini = cputime;

%%%%%%%%%%%%%%%%%%%
% Read image file %
%%%%%%%%%%%%%%%%%%%
% Convert to YCbCr color space
% Expand dimensions to multiples of 8
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
% Scan each component (Y,Cb,Cr) separately and reorder each block in zigzag
% (each scan is an mamp x namp matrix)
XScan = scan(Xlab);

% Encode the three scans using default Huffman tables
[CodedY, CodedCb, CodedCr] = EncodeScans_dflt(XScan);

% Transform obtained Scans tables to bytes and encode them
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

% Write
% Dimensions + caliQ
fwrite(fid, [m n mamp namp caliQ], 'uint32');
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
% Calculate Compression Rate (RC) %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Header length %%%
% header_len=length(n)+length(namp)+length(m)+length(mamp)+length(caliQ);
header_len = 4 * 5; % Size of five uint32 variables (optimized)
data_len = length(sbytes_Y) + length(sbytes_Cb) + length(sbytes_Cr);
TC = header_len + data_len;
RC = 100 * ((TO - TC) / TO);

% Total time
t_total = cputime - t_ini;

%%%%%%% Display information %%%%%%%
if vflag
    fprintf('Tiempo total CPU: %s\n', t_total);
    fprintf('Fichero comprimido generado: %s \n', encoded_file);
    fprintf('Tamaño original: %d \n', TO);
    fprintf('Tamaño comprimido: %d \n', TC);
    fprintf('RC = %f \n', RC);
    fprintf('Terminado jcom_dflt\n');
    fprintf('--------------------------------------------------\n');
end

