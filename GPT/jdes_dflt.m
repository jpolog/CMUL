function [MSE, RC, SNR] = jdes_dflt(fname, extension, show)
% Function: jdes_dflt (Default Huffman table decompression)
% Inputs:
% fname: String containing the file name, including suffix
% extension: String indicating the file extension, e.g., bmp or png
% show: Flag to indicate whether to display the images (optional)
% Outputs:
% MSE: Mean Squared Error between the original and reconstructed images
% RC: Compression ratio
% SNR: Signal-to-Noise Ratio

% Open the compressed file
comp_fich = fopen(fname, 'r');
[Xorig, ~, ~, ~, ~, ~, ~, TO] = imlee(fname);

% Verbosity flag
vflag = 1;
if vflag
    fprintf('Decompressing %s using default Huffman tables...\n\n', fname);
end

% Read the parameters of the original image
[m, n, mamp, namp, caliQ] = fread(comp_fich, 5, 'uint32');

% CodedY
[len_sbytes_Y, ultl_Y] = fread(comp_fich, 2, 'uint32');
sbytes_Y = fread(comp_fich, len_sbytes_Y, 'uint32');
CodedY = bytes2bits(double(sbytes_Y), double(ultl_Y));

% CodedCb
[len_sbytes_Cb, ultl_Cb] = fread(comp_fich, 2, 'uint32');
sbytes_Cb = fread(comp_fich, len_sbytes_Cb, 'uint32');
CodedCb = bytes2bits(double(sbytes_Cb), double(ultl_Cb));

% CodedCr
[len_sbytes_Cr, ultl_Cr] = fread(comp_fich, 2, 'uint32');
sbytes_Cr = fread(comp_fich, len_sbytes_Cr, 'uint32');
CodedCr = bytes2bits(double(sbytes_Cr), double(ultl_Cr));

% Close the file
fclose(comp_fich);

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

% Generate uncompressed file name: <original_name>_des.bmp
% [pathstr, name, ext] = fileparts(fname);
% new_name = strcat(name, '_des_def', '.bmp');

% Save the decompressed file
imwrite(Xrec, new_name, extension);

% Calculate sizes and compression ratio
% header_len=length(n)+length(namp)+length(m)+length(mamp)+length(caliQ);
header_len = 4 * 5; % Optimized calculation (5 parameters * 4 bytes each)
data_len = sum([len_sbytes_Y, len_sbytes_Cb, len_sbytes_Cr]);
TC = header_len + data_len;



% Calculate MSE
% mean across all 3 dimensions
MSE = mean((double(Xrec) - double(Xorig)).^2, [1 2 3]);

% Calculate RC (Compression ratio)
RC = 100 * (TO - TC) / TO;

% Calculate SNR (Signal-to-Noise Ratio)
SNR = 10 * log10(sum(double(Xorig).^2, [1 2 3]) / sum((double(Xrec) - double(Xorig)).^2, [1 2 3]));

% Visual Test of the results
if show
    figure('Name', 'Original Image (Xorig)');
    imshow(Xorig);
    figure('Name', 'Reconstructed Image (Xrec)');
    imshow(Xrec);
end

