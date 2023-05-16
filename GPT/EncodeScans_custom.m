function [CodedY, CodedCb, CodedCr, BITS_Y_DC, HUFFVAL_Y_DC, BITS_Y_AC, HUFFVAL_Y_AC, BITS_C_DC,HUFFVAL_C_DC, BITS_C_AC, HUFFVAL_C_AC]=EncodeScans_custom(XScan)

%  Entradas:
%  XScan: Scans de luminancia Y y crominancia Cb y Cr: Matriz mamp x namp X 3
%  compuesta de:
%   YScan: Scan de luminancia Y: Matriz mamp x namp
%   CbScan: Scan de crominancia Cb: Matriz mamp x namp
%   CrScan: Scan de crominancia Cr: Matriz mamp x namp

% Salidas:
%   CodedY: String binario con scan Y codificado
%   CodedCb: String binario con scan Cb codificado
%   CodedCr: String binario con scan Cr codificado
%   HUFFVAL_Y_DC: símbolos de la fuente, ordenados por longitudes crecientes de la palabra
%   código que les corresponderá¡.
%   BITS_Y_AC: Lista que contiene el número de palabras de cada codigo
%   HUFFVAL_Y_AC: símbolos de la fuente, ordenados por longitudes crecientes de la palabra
%   código que les corresponderá¡.
%   BITS_Y_DC: Lista que contiene el número de palabras de cada codigo
%   HUFFVAL_C_AC: símbolos de la fuente, ordenados por longitudes crecientes de la palabra
%   código que les corresponderá¡.
%   BITS_C_AC: Lista que contiene el número de palabras de cada codigo
%   HUFFVAL_C_DC: símbolos de la fuente, ordenados por longitudes crecientes de la palabra
%   código que les corresponderá¡.
%   BITS_C_DC: Lista que contiene el num. de palabras de cada codigo

% Verbosity flag
vflag = 1;
if vflag
    % Display function name
    fprintf('Encoding using custom Huffman Tables...\n\n');
end

% Get initial time
t_ini=cputime;


% Separa las matrices bidimensionales 
%  para procesar separadamente
YScan=XScan(:,:,1);
CbScan=XScan(:,:,2);
CrScan=XScan(:,:,3);

% Recolectar valores a codificar
[Y_DC_CP, Y_AC_ZCP]=CollectScan(YScan);
[Cb_DC_CP, Cb_AC_ZCP]=CollectScan(CbScan);
[Cr_DC_CP, Cr_AC_ZCP]=CollectScan(CrScan);

% Construir tablas Huffman para Luminancia y Crominancia

% LUMINANCIA
% La primera columna de Y_DC_CP es la secuencia que hay que codificar
FREQ_Y_DC=Freq256((Y_DC_CP(:,1)));
[BITS_Y_DC, HUFFVAL_Y_DC] = HSpecTables(FREQ_Y_DC);

% Tablas Huffman 
[HUFFSIZE_Y_DC, HUFFCODE_Y_DC] = HCodeTables(BITS_Y_DC, HUFFVAL_Y_DC);
[EHUFCO_Y_DC, EHUFSI_Y_DC] = HCodingTables(HUFFSIZE_Y_DC, HUFFCODE_Y_DC, HUFFVAL_Y_DC);
ehuf_Y_DC=[EHUFCO_Y_DC EHUFSI_Y_DC];

% Lo mismo para los valores en zigzag
FREQ_Y_AC=Freq256((Y_AC_ZCP(:,1)));
[BITS_Y_AC, HUFFVAL_Y_AC] = HSpecTables(FREQ_Y_AC);
[HUFFSIZE_Y_AC, HUFFCODE_Y_AC] = HCodeTables(BITS_Y_AC, HUFFVAL_Y_AC);
[EHUFCO_Y_AC, EHUFSI_Y_AC] = HCodingTables(HUFFSIZE_Y_AC, HUFFCODE_Y_AC, HUFFVAL_Y_AC);
ehuf_Y_AC=[EHUFCO_Y_AC EHUFSI_Y_AC];

% CROMINANCIA
% Tabla C_DC : Unión de la tala Cb y Cr
C_DC_CP = [Cb_DC_CP; Cr_DC_CP];

% Y hacemos como antes
FREQ_C_DC=Freq256((C_DC_CP(:,1)));
[BITS_C_DC, HUFFVAL_C_DC] = HSpecTables(FREQ_C_DC);
%Código Huffman
[HUFFSIZE_C_DC, HUFFCODE_C_DC] = HCodeTables(BITS_C_DC, HUFFVAL_C_DC);
%Codificación Huffman
[EHUFCO_C_DC, EHUFSI_C_DC] = HCodingTables(HUFFSIZE_C_DC, HUFFCODE_C_DC, HUFFVAL_C_DC);
ehuf_C_DC=[EHUFCO_C_DC EHUFSI_C_DC];

% Repetimos pero con las operaciones en zigzag
% Tabla C_AC a partir de Cb y Cr
C_AC_ZCP = [Cb_AC_ZCP; Cr_AC_ZCP];
% Y repetimos, como antes
FREQ_C_AC=Freq256((C_AC_ZCP(:,1)));
[BITS_C_AC, HUFFVAL_C_AC] = HSpecTables(FREQ_C_AC);
%Código Huffman
[HUFFSIZE_C_AC, HUFFCODE_C_AC] = HCodeTables(BITS_C_AC, HUFFVAL_C_AC);
%Codificación Huffman
[EHUFCO_C_AC, EHUFSI_C_AC] = HCodingTables(HUFFSIZE_C_AC, HUFFCODE_C_AC, HUFFVAL_C_AC);
ehuf_C_AC =[EHUFCO_C_AC EHUFSI_C_AC];

% Codifica en binario cada Scan
% Las tablas de crominancia, ehuf_C_DC y ehuf_C_AC, se aplican, tanto a Cb, como a Cr
CodedY=EncodeSingleScan(YScan, Y_DC_CP, Y_AC_ZCP, ehuf_Y_DC, ehuf_Y_AC);
CodedCb=EncodeSingleScan(CbScan, Cb_DC_CP, Cb_AC_ZCP, ehuf_C_DC, ehuf_C_AC);
CodedCr=EncodeSingleScan(CrScan, Cr_DC_CP, Cr_AC_ZCP, ehuf_C_DC, ehuf_C_AC);

% Total time
t_total = cputime - t_ini;

if disptext
    fprintf('Componentes codificadas en binario\n');
    fprintf('Total CPU Time: %s\n', t_total);
    fprintf('Terminado EncodeScans_custom\n\n');
end