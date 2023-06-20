function [MSE, RC, SNR] = jdes_dflt(fname, show)
% Function: jdes_dflt (Default Huffman table decompression)
%
% Inputs:
%   fname: String containing the file name, including suffix
%   extension: String indicating the file extension, e.g., bmp or png
%   show: Flag to indicate whether to display the images (optional)
% Outputs:
%   MSE: Mean Squared Error between the original and reconstructed images
%   RC: Compression ratio
%   SNR: Signal-to-Noise Ratio
%
% Author:  Javier Polo Gambin - PCEO
    

% Paths to original and decoded images
orig_filepath = '../Images/original/'; 
dec_filepath = '../Images/decoded_dflt/';

% Open the compressed file
[~, name, ~] = fileparts(fname);
tmp = strsplit(name, "_Q");
basename = tmp(1); % used to open original file + generate decompressed file
enc_fid = fopen(fname, 'r');

% Verbosity flag
vflag = 1;
if vflag
    fprintf('--------------------------------------------------\n');
    fprintf('Funcion djes_dflt:\n');
    fprintf('Descomprimiendo %s usando tablas Huffman Default...\n\n', fname);
end

% Read the parameters of the original image
params = fread(enc_fid, 5, 'uint32');
[m, n, mamp, namp, caliQ] = deal(params(1),params(2),params(3),params(4),params(5));

% CodedY
len_sbytes_Y = fread(enc_fid, 1, 'uint32');
sbytes_Y = fread(enc_fid, len_sbytes_Y, 'uint32');
ultl_Y = fread(enc_fid, 1, 'uint32');
CodedY = bytes2bits(double(sbytes_Y), double(ultl_Y));

% CodedCb
len_sbytes_Cb = fread(enc_fid, 1, 'uint32');
sbytes_Cb = fread(enc_fid, len_sbytes_Cb, 'uint32');
ultl_Cb = fread(enc_fid, 1, 'uint32');
CodedCb = bytes2bits(double(sbytes_Cb), double(ultl_Cb));

% CodedCr
len_sbytes_Cr = fread(enc_fid, 1, 'uint32');
sbytes_Cr = fread(enc_fid, len_sbytes_Cr, 'uint32');
ultl_Cr = fread(enc_fid, 1, 'uint32');
CodedCr = bytes2bits(double(sbytes_Cr), double(ultl_Cr));

% Close the file
fclose(enc_fid);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Decode 3 scans from binary strings %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
XScanrec = DecodeScans_dflt(CodedY, CodedCb, CodedCr, [mamp, namp]);

% Recover natural order label matrices from zigzag order
Xlabrec = invscan(XScanrec);

% Dequantization of labels
Xtransrec = desquantmat(Xlabrec, caliQ);

% Perform 2D inverse DCT on 8x8 pixel blocks
% Reconstructs an extended size YCbCr image
Xamprec = imidct(Xtransrec, m, n);

% Convert to RGB color space
% Obs: When using ycbcr2rgb
%   1 We have to scale the values to [0,1] before converting
%   2 Output image in RGB will have values in the range [0,1].
%   3 And then scale back to [0,255] range
%	4 round and convert to 8-bit int
Xrec_rgb = uint8(round(ycbcr2rgb(Xamprec / 255) * 255)); % Recovered image

% Restore the original size
Xrec = Xrec_rgb(1:m, 1:n, :);

% Generate decompressed file
dec_file = strcat(dec_filepath, basename,'_Q',num2str(caliQ),'_dec_dflt', '.bmp');
% Save the decompressed file
imwrite(Xrec, dec_file);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate compression metrics %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Calculate sizes and compression ratio
% header_len=length(n)+length(namp)+length(m)+length(mamp)+length(caliQ);
header_len = 4 * 5; % Optimized calculation (5 parameters * 4 bytes each)
data_len = sum([len_sbytes_Y, len_sbytes_Cb, len_sbytes_Cr]);
TC = header_len + data_len;


% Open the original image
orig_file = strcat(orig_filepath, basename, '.bmp');
[Xorig, ~, ~, ~, ~, ~, ~, TO] = imlee(orig_file);

% Calculate MSE
% mean across all 3 dimensions
MSE = mean((double(Xrec) - double(Xorig)).^2, [1 2 3]);

% Calculate RC (Compression ratio)
RC = 100 * (TO - TC) / TO;

% Calculate SNR (Signal-to-Noise Ratio)
SNR = 10 * log10(sum(double(Xorig).^2, [1 2 3]) / sum((double(Xrec) - double(Xorig)).^2, [1 2 3]));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Visual Test of the results %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Don't show images by default
if nargin < 2
    show = false;
end

if show
    figure('Name', 'Imagen Original');
    imshow(Xorig);
    figure('Name', 'Imagen Reconstruida');
    imshow(Xrec);
end

if vflag
    fprintf('Terminado jdes_dflt\n');
    fprintf('--------------------------------------------------\n');
end