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
m = double(fread(comp_fich, 1, 'uint32'));
n = double(fread(comp_fich, 1, 'uint32'));
mamp = double(fread(comp_fich, 1, 'uint32'));
namp = double(fread(comp_fich, 1, 'uint32'));
caliQ = double(fread(comp_fich, 1, 'uint32'));

% CodedY
len_sbytes_Y = double(fread(comp_fich, 1, 'uint32'));
ultl_Y = double(fread(comp_fich, 1, 'uint32'));
sbytes_Y = fread(comp_fich, len_sbytes_Y, 'uint32');
sbytes_Y = double(sbytes_Y);
% Obtain original CodedY
CodedY = bytes2bits(sbytes_Y, ultl_Y);

% CodedCb
len_sbytes_Cb = double(fread(comp_fich, 1, 'uint32'));
ultl_Cb = double(fread(comp_fich, 1, 'uint32'));
sbytes_Cb = fread(comp_fich, len_sbytes_Cb, 'uint32');
sbytes_Cb = double(sbytes_Cb);
% Obtain original CodedCb
CodedCb = bytes2bits(sbytes_Cb, ultl_Cb);

% CodedCr
len_sbytes_Cr = double(fread(comp_fich, 1, 'uint32'));
ultl_Cr = double(fread(comp_fich, 1, 'uint32'));
sbytes_Cr = fread(comp_fich, len_sbytes_Cr, 'uint32');
sbytes_Cr = double(sbytes_Cr);
% Obtain original CodedCr
CodedCr = bytes2bits(sbytes_Cr, ultl_Cr);

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
Xrec_rgb = round(ycbcr2rgb(Xamprec / 255) * 255);
Xrec = uint8(Xrec_rgb); % Recovered image

% Restore the original size
Xrec = Xrec(1:m, 1:n, 1:3);

% Generate uncompressed file name: <original_name>_des.bmp
% [pathstr, name, ext] = fileparts(fname);
% new_name = strcat(name, '_des_def', '.bmp');

% Save the decompressed file
imwrite(Xrec, new_name, extension);

% header_len=length(n)+length(namp)+length(m)+length(mamp)+length(caliQ);
% each of them will occupy 4 bytes
TAM_CAB = 4 * 5; % Optimized calculation
TAM_DAT = length(sbytes_Y) + length(sbytes_Cb) + length(sbytes_Cr);
TC = TAM_CAB + TAM_DAT;

% Calculate MSE
% MSE = (sum(sum(sum((double(Xrec) - double(Xorig)).^2)))) / (m * n * 3);
% Sum 3 times to sum across all dimensions
MSE = mean((sum(sum(sum((double(Xrec) - double(Xorig)).^2)))));

% Calculate RC (Compression ratio)
%%%> Should it be TAM_DAT or TC here???
RC = 100 * (TO - TC) / TO;

% Calculate SNR (Signal-to-Noise Ratio)
SNR = sum(sum(sum(double(Xorig).^2))) / (sum(sum(sum((double(Xrec) - double(Xorig)).^2))));
SNR = 10 * log10(SNR);

% Visual Test of the results
if show
    [m, n, ~] = size(Xorig);
    figure('Units', 'pixels', 'Position', [100 100 n m]);
    set(gca, 'Position', [0 0 1 1]);
    image(Xorig);
    set(gcf, 'Name', 'Original Image (Xorig)');
    figure('Units', 'pixels', 'Position', [100 100 n m]);
    set(gca, 'Position', [0 0 1 1]);
    image(Xrec);
    set(gcf, 'Name', 'Reconstructed Image (Xrec)');
end

end
