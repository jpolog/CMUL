function XScanrec = DecodeScans_custom(CodedY, CodedCb, CodedCr, TAM, BITS_Y_DC, HUFFVAL_Y_DC, BITS_Y_AC, HUFFVAL_Y_AC, BITS_C_DC, HUFFVAL_C_DC, BITS_C_AC, HUFFVAL_C_AC)
% Function: DecodeScans_custom
% Inputs:
%   CodedY: Encoded luminance data
%   CodedCb: Encoded Cb chrominance data
%   CodedCr: Encoded Cr chrominance data
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
    % Display function name
    fprintf('Decoding using custom Huffman Tables...\n\n');
end

% Get initial time
t_ini = cputime;

% Construct Huffman tables for luminance and chrominance
% Luminance tables
% Y_DC table
% First, create the Huffman code table and then the decoding table.
[HUFFSIZE_Y_DC, HUFFCODE_Y_DC] = HCodeTables(BITS_Y_DC, HUFFVAL_Y_DC);
[MINCO_Y_DC, MAXCO_Y_DC, VALPTR_Y_DC] = HDecodingTables(BITS_Y_DC, HUFFCODE_Y_DC);

% Y_AC table
[HUFFSIZE_Y_AC, HUFFCODE_Y_AC] = HCodeTables(BITS_Y_AC, HUFFVAL_Y_AC);
[MINCO_Y_AC, MAXCO_Y_AC, VALPTR_Y_AC] = HDecodingTables(BITS_Y_AC, HUFFCODE_Y_AC);

% Decode the luminance table
YRec = DecodeSingleScan(CodedY, MINCO_Y_DC, MAXCO_Y_DC, VALPTR_Y_DC, HUFFVAL_Y_DC, MINCO_Y_AC, MAXCO_Y_AC, VALPTR_Y_AC, HUFFVAL_Y_AC, TAM);

% Chrominance tables
% C_DC and C_AC tables
% First, create the Huffman code table and then the decoding table.
[HUFFSIZE_C_DC, HUFFCODE_C_DC] = HCodeTables(BITS_C_DC, HUFFVAL_C_DC);
[MINCO_C_DC, MAXCO_C_DC, VALPTR_C_DC] = HDecodingTables(BITS_C_DC, HUFFCODE_C_DC);

[HUFFSIZE_C_AC, HUFFCODE_C_AC] = HCodeTables(BITS_C_AC, HUFFVAL_C_AC);
[MINCO_C_AC, MAXCO_C_AC, VALPTR_C_AC] = HDecodingTables(BITS_C_AC, HUFFCODE_C_AC);

% Decode the chrominance tables
CBRec = DecodeSingleScan(CodedCb, MINCO_C_DC, MAXCO_C_DC, VALPTR_C_DC, HUFFVAL_C_DC, MINCO_C_AC, MAXCO_C_AC, VALPTR_C_AC, HUFFVAL_C_AC, TAM);
CRRec = DecodeSingleScan(CodedCr, MINCO_C_DC, MAXCO_C_DC, VALPTR_C_DC, HUFFVAL_C_DC, MINCO_C_AC, MAXCO_C_AC, VALPTR_C_AC, HUFFVAL_C_AC, TAM);

% Reconstruct the 3-D matrix from the 3 components
XScanrec = cat(3, YRec, CBRec, CRRec);

% Total time
t_total = cputime - t_ini;

if vflag
    fprintf('Scans have been decoded\n')
    fprintf('Total CPU Time: %s\n', t_total);
    fprintf('DecodeScans_custom finished\n');
end