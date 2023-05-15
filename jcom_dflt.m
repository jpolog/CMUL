function RC = jcom_dflt(fname, caliQ, extension)

% Function: jcom_dflt (Default Huffman table compression)
% Inputs:
% fname: String containing the file name, including suffix
% Accepts BMP and JPEG, indexed and truecolor
% caliQ: Quality factor (positive integer >= 1)
% 100: standard quality
% >100: lower quality
% <100: higher quality
% extension: String indicating the file extension, e.g., bmp or png
% Outputs:
% RC: Compression ratio

% Verbosity flag
vflag = 1;
if vflag
% Display function name
    fprintf('Compressing %s using default Huffman compression...\n\n', fname);
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

% Encode the three scans using default Huffman tables
[CodedY,CodedCb,CodedCr]=EncodeScans_dflt(XScan);

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

% Write
fwrite(fid,n,'uint32');
fwrite(fid,namp,'uint32');
fwrite(fid,m,'uint32');
fwrite(fid,mamp,'uint32');
fwrite(fid,caliQ,'uint32');
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
header_len=length(n)+length(namp)+length(m)+length(mamp)+length(caliQ);
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
    