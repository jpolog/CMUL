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
    fprintf('Compressing %s using custom Huffman compression...\n\n', file_name);
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





