function [MSE, RC, SNR] = jdes_custom(fname, extension, show)
% Function: jdes_custom (Custom Huffman table decompression)
% Inputs:
% fname: String containing the file name, including suffix
% extension: String indicating the file extension, e.g., bmp or png
% show: Flag to indicate whether to display the images (optional)
% Outputs:
% MSE: Mean Squared Error between the original and reconstructed images
% RC: Compression ratio
% SNR: Signal-to-Noise Ratio

% Open the compressed file
fid = fopen(fname, 'r');
[Xorig, ~, ~, ~, ~, ~, ~, TO] = imlee(fname);

% Verbosity flag
vflag = 1;
if vflag
    fprintf('Decompressing %s using custom Huffman tables...\n\n', fname);
end

% Read the parameters of the original image
[m, n, mamp, namp, caliQ] = fread(fid, 5, 'uint32');

% Read BITS and HUFFMAN from the file header
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

% Read the 3 compressed channels
% CodedY
[len_sbytes_Y, ultl_Y] = fread(fid, 2, 'uint32');
sbytes_Y = fread(fid, len_sbytes_Y, 'uint32');
CodedY = bytes2bits(double(sbytes_Y), double(ultl_Y));
% CodedCb
[len_sbytes_Cb, ultl_Cb] = fread(fid, 2, 'uint32');
sbytes_Cb = fread(fid, len_sbytes_Cb, 'uint32');
CodedCb = bytes2bits(double(sbytes_Cb), double(ultl_Cb));
% CodedCr
[len_sbytes_Cr, ultl_Cr] = fread(fid, 2, 'uint32');
sbytes_Cr = fread(fid, len_sbytes_Cr, 'uint32');
CodedCr = bytes2bits(double(sbytes_Cr), double(ultl_Cr));

% Close the file
fclose(fid);

% Decode the three scans from binary strings using custom Huffman tables
XScanrec = DecodeScans_custom(CodedY, CodedCb, CodedCr, [mamp namp], ...
    BITS_Y_DC, HUFFVAL_Y_DC, BITS_Y_AC, HUFFVAL_Y_AC, ...
    BITS_C_DC, HUFFVAL_C_DC, BITS_C_AC, HUFFVAL_C_AC);

% Recover label matrices in natural order from zigzag order
Xlabrec = invscan(XScanrec);

% Dequantize labels
Xtransrec = desquantmat(Xlabrec, caliQ);

% Perform 2D iDCT on 8x8 pixel blocks
Xamprec = imidct(Xtransrec, m, n);

% Convert to RGB color space
% Note:
% 1. Scale the values to [0,1] before converting
% 2. Output image in RGB will have values in the range [0,1]
% 3. Scale back to the [0,255] range
% 4. Round and convert to 8-bit integer
Xrec_rgb = uint8(round(ycbcr2rgb(Xamprec / 255) * 255));

% Restore the original size
Xrec = Xrec_rgb(1:m, 1:n, 1:3);

% Save the decompressed file
imwrite(Xrec, [fname, '.', extension]);

% Calculate header length and total compressed data length
% Note:
% first elements of the header are n,m,mamp,namp,caliQ = 5 elem * 4 bytes
% Then for each header value we have the length (4 bytes) and the 
% actual size (length * 4 bytes)
header_len = 4 * 5 + (1 + len_BITS_Y_DC) * 4 + (1 + len_HUFFVAL_Y_DC) * 4 ...
+ (1 + len_BITS_Y_AC) * 4 + (1 + len_HUFFVAL_Y_AC) * 4 ...
+ (1 + len_BITS_C_DC) * 4 + (1 + len_HUFFVAL_C_DC) * 4 ...
+ (1 + len_BITS_C_AC) * 4 + (1 + len_HUFFVAL_C_AC) * 4;
data_len = sum([len_sbytes_Y, len_sbytes_Cb, len_sbytes_Cr]);
TC = header_len + data_len;

% Calculate MSE
% mean across all 3 dimensions
MSE = mean((double(Xrec) - double(Xorigig)).^2, [1 2 3]);

% Calculate Compression Ratio (RC)
RC = 100 * (TO - TC) / TO;

% Calculate SNR (Signal-to-Noise Ratio)
SNR = 10 * log10(sum(double(Xorigig).^2, [1 2 3]) / sum((double(Xrec) - double(Xorigig)).^2, [1 2 3]));


% Visual test
if show
    figure('Name', 'Original Image (Xorig)');
    imshow(Xorig);
    figure('Name', 'Reconstructed Image (Xrec)');
    imshow(Xrec);
end



