function XScanrec = DecodeScans_custom(CodedY, CodedCb, CodedCr, TAM, BITS_Y_DC, HUFFVAL_Y_DC, BITS_Y_AC, HUFFVAL_Y_AC, BITS_C_DC, HUFFVAL_C_DC, BITS_C_AC, HUFFVAL_C_AC)
% Function: DecodeScans_custom: Decodes scans of luminance Y and chrominance 
% Cb and Cr using custom Huffman tables
%
% Inputs:
%   CodedY: Encoded luminance scan
%   CodedCb: Encoded Cb chrominance scan
%   CodedCr: Encoded Cr chrominance scan
%   TAM: Size of the image [m, n]
%   BITS_Y_DC, HUFFVAL_Y_DC: Huffman tables for luminance DC component
%   BITS_Y_AC, HUFFVAL_Y_AC: Huffman tables for luminance AC component
%   BITS_C_DC, HUFFVAL_C_DC: Huffman tables for chrominance DC component
%   BITS_C_AC, HUFFVAL_C_AC: Huffman tables for chrominance AC component
% Outputs:
%   XScanrec: Reconstructed 3-D matrix (Y, Cb, Cr) after decoding the scans

% Verbosity flag
vflag = 1;
if vflag
    fprintf('--------------------------------------------------\n');
    fprintf('Funcion DecodeScans_custom:\n');
    fprintf('Decodificando usando Tablas Huffman Custom...\n');
end

% Get initial time
t_ini = cputime;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create Huffman coding and decoding tables %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Luminance DC table (Y_DC)
[HUFFSIZE_Y_DC, HUFFCODE_Y_DC] = HCodeTables(BITS_Y_DC, HUFFVAL_Y_DC);
% Decoding table
[MIN_Y_DC, MAX_Y_DC, VAL_Y_DC] = HDecodingTables(BITS_Y_DC, HUFFCODE_Y_DC);

% Luminance AC table (Y_AC)
[HUFFSIZE_Y_AC, HUFFCODE_Y_AC] = HCodeTables(BITS_Y_AC, HUFFVAL_Y_AC);
% Decoding table
[MIN_Y_AC, MAX_Y_AC, VAL_Y_AC] = HDecodingTables(BITS_Y_AC, HUFFCODE_Y_AC);

% Chrominance C_DC table
[HUFFSIZE_C_DC, HUFFCODE_C_DC] = HCodeTables(BITS_C_DC, HUFFVAL_C_DC);
% Decoding table
[MIN_C_DC, MAX_C_DC, VAL_C_DC] = HDecodingTables(BITS_C_DC, HUFFCODE_C_DC);

% Chrominance C_AC table
[HUFFSIZE_C_AC, HUFFCODE_C_AC] = HCodeTables(BITS_C_AC, HUFFVAL_C_AC);
% Decoding table
[MIN_C_AC, MAX_C_AC, VAL_C_AC] = HDecodingTables(BITS_C_AC, HUFFCODE_C_AC);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Decode the luminance and chrominance scans %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Y = DecodeSingleScan(CodedY, MIN_Y_DC, MAX_Y_DC, VAL_Y_DC, HUFFVAL_Y_DC, MIN_Y_AC, MAX_Y_AC, VAL_Y_AC, HUFFVAL_Y_AC, TAM);
CB = DecodeSingleScan(CodedCb, MIN_C_DC, MAX_C_DC, VAL_C_DC, HUFFVAL_C_DC, MIN_C_AC, MAX_C_AC, VAL_C_AC, HUFFVAL_C_AC, TAM);
CR = DecodeSingleScan(CodedCr, MIN_C_DC, MAX_C_DC, VAL_C_DC, HUFFVAL_C_DC, MIN_C_AC, MAX_C_AC, VAL_C_AC, HUFFVAL_C_AC, TAM);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Build the 3-D matrix (Y,Cb,Cr) %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
XScanrec = cat(3, Y, CB, CR);

% Total time
t_total = cputime - t_ini;

if vflag
fprintf('Los escaneos se han decodificado\n')
fprintf('Terminado DecodeScans_custom\n');
fprintf('Tiempo total CPU: %s\n', t_total);
fprintf('--------------------------------------------------\n');
end