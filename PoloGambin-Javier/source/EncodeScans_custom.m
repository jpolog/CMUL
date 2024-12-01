function [CodedY, CodedCb, CodedCr, BITS_Y_DC, HUFFVAL_Y_DC, BITS_Y_AC, HUFFVAL_Y_AC, BITS_C_DC, HUFFVAL_C_DC, BITS_C_AC, HUFFVAL_C_AC] = EncodeScans_custom(XScan)
% EncodeScans_custom: Encodes scans of luminance Y and chrominance Cb and Cr using custom Huffman tables.
% Inputs:
%   XScan: Scans of luminance Y and chrominance Cb and Cr. Matrix with 3 dimensions:
%          - YScan: Luminance Y scan
%          - CbScan: Cb chrominance scan
%          - CrScan: Cr chrominance scan
% Outputs:
%   CodedY: Encoded Y scan
%   CodedCb: Encoded Cb scan
%   CodedCr: Encoded Cr scan
%   BITS_Y_DC: List containing the number of codewords for each code in the luminance DC component
%   HUFFVAL_Y_DC: Source symbols ordered by increasing word lengths of their corresponding code
%   BITS_Y_AC: List containing the number of codewords for each code in the luminance AC component
%   HUFFVAL_Y_AC: Source symbols ordered by increasing word lengths of their corresponding code
%   BITS_C_DC: List containing the number of codewords for each code in the chrominance DC component
%   HUFFVAL_C_DC: Source symbols ordered by increasing word lengths of their corresponding code
%   BITS_C_AC: List containing the number of codewords for each code in the chrominance AC component
%   HUFFVAL_C_AC: Source symbols ordered by increasing word lengths of their corresponding code

% Verbosity flag
vflag = 1;
if vflag
    fprintf('--------------------------------------------------\n');
    fprintf('Funcion EncodeScans_custom:\n');
    fprintf('Codificando usando Tablas Huffman Custom...\n');
end

% Get initial time
t_ini = cputime;

% Separate each of the scans
YScan = XScan(:, :, 1);
CbScan = XScan(:, :, 2);
CrScan = XScan(:, :, 3);

% Values to encode
% the first component of each value is the sequence that 
% needs to be encoded
[Y_DC_CP, Y_AC_ZCP] = CollectScan(YScan);
[Cb_DC_CP, Cb_AC_ZCP] = CollectScan(CbScan);
[Cr_DC_CP, Cr_AC_ZCP] = CollectScan(CrScan);

%%%%%%%%%%%%%%%%%%%%%%%%%
% Create Huffman tables %
%%%%%%%%%%%%%%%%%%%%%%%%%
% Luminance DC table
% Calculate frequency
FREQ_Y_DC = Freq256(Y_DC_CP(:, 1));
% Calculate BITS and HUFFVAL tables from Frequency
[BITS_Y_DC, HUFFVAL_Y_DC] = HSpecTables(FREQ_Y_DC);
% Create Huffman table
[HUFFSIZE_Y_DC, HUFFCODE_Y_DC] = HCodeTables(BITS_Y_DC, HUFFVAL_Y_DC);
[EHUFCO_Y_DC, EHUFSI_Y_DC] = HCodingTables(HUFFSIZE_Y_DC, HUFFCODE_Y_DC, HUFFVAL_Y_DC);
ehuf_Y_DC = [EHUFCO_Y_DC EHUFSI_Y_DC];

% Luminance AC table
FREQ_Y_AC = Freq256(Y_AC_ZCP(:, 1));
[BITS_Y_AC, HUFFVAL_Y_AC] = HSpecTables(FREQ_Y_AC);
[HUFFSIZE_Y_AC, HUFFCODE_Y_AC] = HCodeTables(BITS_Y_AC, HUFFVAL_Y_AC);
[EHUFCO_Y_AC, EHUFSI_Y_AC] = HCodingTables(HUFFSIZE_Y_AC, HUFFCODE_Y_AC, HUFFVAL_Y_AC);
ehuf_Y_AC = [EHUFCO_Y_AC EHUFSI_Y_AC];

% Chrominance DC table
% Cb and Cr tables combined
C_DC_CP = [Cb_DC_CP; Cr_DC_CP]; %Combine Cb and Cr
FREQ_C_DC = Freq256(C_DC_CP(:, 1));
[BITS_C_DC, HUFFVAL_C_DC] = HSpecTables(FREQ_C_DC);
[HUFFSIZE_C_DC, HUFFCODE_C_DC] = HCodeTables(BITS_C_DC, HUFFVAL_C_DC);
[EHUFCO_C_DC, EHUFSI_C_DC] = HCodingTables(HUFFSIZE_C_DC, HUFFCODE_C_DC, HUFFVAL_C_DC);
ehuf_C_DC = [EHUFCO_C_DC EHUFSI_C_DC];

% Chrominance AC table
% Cb and Cr tables combined
C_AC_ZCP = [Cb_AC_ZCP; Cr_AC_ZCP]; %Combine Cb and Cr
FREQ_C_AC = Freq256(C_AC_ZCP(:, 1));
[BITS_C_AC, HUFFVAL_C_AC] = HSpecTables(FREQ_C_AC);
[HUFFSIZE_C_AC, HUFFCODE_C_AC] = HCodeTables(BITS_C_AC, HUFFVAL_C_AC);
[EHUFCO_C_AC, EHUFSI_C_AC] = HCodingTables(HUFFSIZE_C_AC, HUFFCODE_C_AC, HUFFVAL_C_AC);
ehuf_C_AC = [EHUFCO_C_AC EHUFSI_C_AC];

% Encode each scan into binary using Huffman coding and the tables
% calculated before
% Luminance
CodedY = EncodeSingleScan(YScan, Y_DC_CP, Y_AC_ZCP, ehuf_Y_DC, ehuf_Y_AC);
% Chrominance
CodedCb = EncodeSingleScan(CbScan, Cb_DC_CP, Cb_AC_ZCP, ehuf_C_DC, ehuf_C_AC);
CodedCr = EncodeSingleScan(CrScan, Cr_DC_CP, Cr_AC_ZCP, ehuf_C_DC, ehuf_C_AC);

% Calculate total time
t_total = cputime - t_ini;

if vflag
fprintf('Componentes codificados\n');
fprintf('Terminado EncodeScans_custom\n');
fprintf('Tiempo total CPU: %s\n', t_total);
fprintf('--------------------------------------------------\n');
end
