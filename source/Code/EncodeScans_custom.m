function [CodedY, CodedCb, CodedCr, BITS_Y_DC, HUFFVAL_Y_DC, BITS_Y_AC, HUFFVAL_Y_AC, BITS_C_DC, HUFFVAL_C_DC, BITS_C_AC, HUFFVAL_C_AC] = EncodeScans_custom(XScan)
% EncodeScans_custom: Encodes scans of luminance Y and chrominance Cb and Cr using custom Huffman tables.
% Inputs:
%   XScan: Scans of luminance Y and chrominance Cb and Cr: mamp x namp x 3 matrix composed of:
%          - YScan: Luminance Y scan: mamp x namp matrix
%          - CbScan: Cb chrominance scan: mamp x namp matrix
%          - CrScan: Cr chrominance scan: mamp x namp matrix
% Outputs:
%   CodedY: Binary string with encoded Y scan
%   CodedCb: Binary string with encoded Cb scan
%   CodedCr: Binary string with encoded Cr scan
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
    % Display function name
    fprintf('Encoding using custom Huffman Tables...\n\n');
end

% Get initial time
t_ini = cputime;

% Separate the 2D matrices to process them separately
YScan = XScan(:, :, 1);
CbScan = XScan(:, :, 2);
CrScan = XScan(:, :, 3);

% Collect values to encode
[Y_DC_CP, Y_AC_ZCP] = CollectScan(YScan);
[Cb_DC_CP, Cb_AC_ZCP] = CollectScan(CbScan);
[Cr_DC_CP, Cr_AC_ZCP] = CollectScan(CrScan);

% Construct Huffman tables for luminance and chrominance

% Luminance DC table
% The first column of Y_DC_CP is the sequence to be encoded
FREQ_Y_DC = Freq256(Y_DC_CP(:, 1));
[BITS_Y_DC, HUFFVAL_Y_DC] = HSpecTables(FREQ_Y_DC);

% Huffman tables for luminance DC
[HUFFSIZE_Y_DC, HUFFCODE_Y_DC] = HCodeTables(BITS_Y_DC, HUFFVAL_Y_DC);
[EHUFCO_Y_DC, EHUFSI_Y_DC] = HCodingTables(HUFFSIZE_Y_DC, HUFFCODE_Y_DC, HUFFVAL_Y_DC);
ehuf_Y_DC = [EHUFCO_Y_DC EHUFSI_Y_DC];

% Luminance AC table
% Same procedure as DC table
FREQ_Y_AC = Freq256(Y_AC_ZCP(:, 1));
[BITS_Y_AC, HUFFVAL_Y_AC] = HSpecTables(FREQ_Y_AC);
[HUFFSIZE_Y_AC, HUFFCODE_Y_AC] = HCodeTables(BITS_Y_AC, HUFFVAL_Y_AC);
[EHUFCO_Y_AC, EHUFSI_Y_AC] = HCodingTables(HUFFSIZE_Y_AC, HUFFCODE_Y_AC, HUFFVAL_Y_AC);
ehuf_Y_AC = [EHUFCO_Y_AC EHUFSI_Y_AC];

% Chrominance DC table
% Combination of Cb and Cr tables
C_DC_CP = [Cb_DC_CP; Cr_DC_CP];

% Repeat the process for chrominance DC
FREQ_C_DC = Freq256(C_DC_CP(:, 1));
[BITS_C_DC, HUFFVAL_C_DC] = HSpecTables(FREQ_C_DC);
[HUFFSIZE_C_DC, HUFFCODE_C_DC] = HCodeTables(BITS_C_DC, HUFFVAL_C_DC);
[EHUFCO_C_DC, EHUFSI_C_DC] = HCodingTables(HUFFSIZE_C_DC, HUFFCODE_C_DC, HUFFVAL_C_DC);
ehuf_C_DC = [EHUFCO_C_DC EHUFSI_C_DC];

% Chrominance AC table
% Repeat the previous steps for chrominance AC
C_AC_ZCP = [Cb_AC_ZCP; Cr_AC_ZCP];
FREQ_C_AC = Freq256(C_AC_ZCP(:, 1));
[BITS_C_AC, HUFFVAL_C_AC] = HSpecTables(FREQ_C_AC);
[HUFFSIZE_C_AC, HUFFCODE_C_AC] = HCodeTables(BITS_C_AC, HUFFVAL_C_AC);
[EHUFCO_C_AC, EHUFSI_C_AC] = HCodingTables(HUFFSIZE_C_AC, HUFFCODE_C_AC, HUFFVAL_C_AC);
ehuf_C_AC = [EHUFCO_C_AC EHUFSI_C_AC];

% Encode each scan into binary
% Apply the chrominance tables, ehuf_C_DC and ehuf_C_AC, to both Cb and Cr
CodedY = EncodeSingleScan(YScan, Y_DC_CP, Y_AC_ZCP, ehuf_Y_DC, ehuf_Y_AC);
CodedCb = EncodeSingleScan(CbScan, Cb_DC_CP, Cb_AC_ZCP, ehuf_C_DC, ehuf_C_AC);
CodedCr = EncodeSingleScan(CrScan, Cr_DC_CP, Cr_AC_ZCP, ehuf_C_DC, ehuf_C_AC);

% Calculate total time
t_total = cputime - t_ini;

if vflag
fprintf('Components encoded in binary\n');
fprintf('Total CPU Time: %s\n', t_total);
fprintf('EncodeScans_custom finished\n\n');
end
