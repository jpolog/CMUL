function RC = jcom_custom(fname, caliQ, extension)
% jcom_custom: Image compression based on customized Huffman tables
%
% Inputs:
%   fname: File name string, including suffix
%          Supports BMP and JPEG, indexed and truecolor
%   caliQ: Quality factor (positive integer >= 1)
%          100: standard quality
%          >100: lower quality
%          <100: higher quality
%   extension: String indicating the file extension (e.g., bmp or png)
%
% Outputs:
%   RC: Compression ratio

% Verbosity flag
vflag = 1;
if vflag
    % Display function name
    fprintf('Compressing %s using custom Huffman compression...\n\n', fname);
end

% Get initial CPU time
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
Xtrans = perform_dct(Xamp);

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

% Encode the three scans using custom Huffman tables
[CodedY, CodedCb, CodedCr, BITS_Y_DC, HUFFVAL_Y_DC, BITS_Y_AC, HUFFVAL_Y_AC, BITS_C_DC, HUFFVAL_C_DC, BITS_C_AC, HUFFVAL_C_AC] = EncodeScans_custom(XScan);

% Transform obtained Scan tables to bytes and encode them
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

% We need to encode the generated Bits and Huffval tables too
% to store them in the compressed file
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

% Generate compressed file name (.hud extension)
[~, name, ~] = fileparts(fname);
compressed_filename = strcat(name, '.hud');

% Create the compressed file
comp_fich = fopen(compressed_filename, 'w');

%%% Write %%%
% Dimensions + caliQ
fwrite(comp_fich, [m n mamp namp caliQ], 'uint32');
% Bits & Huffval encoded tables (length + value)
% Y_DC
fwrite(comp_fich, len_BITS_Y_DC, 'uint32');
fwrite(comp_fich, BITS_Y_DC, 'uint32');
fwrite(comp_fich, len_HUFFVAL_Y_DC, 'uint32');
fwrite(comp_fich, HUFFVAL_Y_DC, 'uint32');
% Y_AC
fwrite(comp_fich, len_BITS_Y_AC, 'uint32');
fwrite(comp_fich, BITS_Y_AC, 'uint32');
fwrite(comp_fich, len_HUFFVAL_Y_AC, 'uint32');
fwrite(comp_fich, HUFFVAL_Y_AC, 'uint32');
% C_DC
fwrite(comp_fich, len_BITS_C_DC, 'uint32');
fwrite(comp_fich, BITS_C_DC, 'uint32');
fwrite(comp_fich, len_HUFFVAL_C_DC, 'uint32');
fwrite(comp_fich, HUFFVAL_C_DC, 'uint32');
% C_AC
fwrite(comp_fich, len_BITS_C_AC, 'uint32');
fwrite(comp_fich, BITS_C_AC, 'uint32');
fwrite(comp_fich, len_HUFFVAL_C_AC, 'uint32');
fwrite(comp_fich, HUFFVAL_C_AC, 'uint32');

% Coded Scans of each component
% CodedY
fwrite(comp_fich, len_sbytes_Y, 'uint32');
fwrite(comp_fich, sbytes_Y, 'uint32');
fwrite(comp_fich, ultl_Y, 'uint32');

% CodedCb
fwrite(comp_fich, len_sbytes_Cb, 'uint32');
fwrite(comp_fich, sbytes_Cb, 'uint32');
fwrite(comp_fich, ultl_Cb, 'uint32');

% CodedCr
fwrite(comp_fich, len_sbytes_Cr, 'uint32');
fwrite(comp_fich, sbytes_Cr, 'uint32');
fwrite(comp_fich, ultl_Cr, 'uint32');

% Close file
fclose(comp_fich);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate Compression Rate (RC) %
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

%%%%% Compression Rate %%%%%
RC = 100 * ((TO - TC) / TO);


% Total CPU time
t_total = cputime - t_ini;


%%%%%%% Display information
if vflag
    fprintf('Total CPU Time: %s\n', t_total);
    fprintf('Generated compressed file: %s \n', compressed_filename);
    fprintf('Original size: %d \n', TO);
    fprintf('Compressed size: %d \n', TC);
    fprintf('RC = %f \n', RC);
    fprintf('Finished Default Huffman Compression\n\n');
end


