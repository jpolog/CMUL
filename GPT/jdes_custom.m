function [MSE,RC,SNR] = jdes_custom(fname, extension, show) 



% Open the compressed file
fid = fopen(fname,'r');
[XOR, ~, ~, ~, ~, ~, ~, TO] = imlee(archivoOrig);




% Verbosity flag
vflag = 1;
if vflag
    fprintf('Decompressing %s using custom Huffman tables...\n\n', fname);
end

% Leemos los parámetros de la imagen original
m = double(fread(fid, 1, 'uint32'));    
n = double(fread(fid, 1, 'uint32'));   
mamp = double(fread(fid, 1, 'uint32'));  
namp = double(fread(fid, 1, 'uint32'));  
caliQ = double(fread(fid, 1, 'uint32')); 

% Leemos BITS y HUFFMAN de la cabecera del fichero
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

% Leemos los 3 canales comprimidos
% CodedY
len_sbytes_Y = double(fread(fid, 1, 'uint32'));
ultl_Y = double(fread(fid, 1, 'uint32'));
sbytes_Y = double(fread(fid, len_sbytes_Y, 'uint32'));
sbytes_Y = double(sbytes_Y);
% Obtenemos CodedY original
CodedY=bytes2bits(sbytes_Y, ultl_Y);

% CodedCb
len_sbytes_Cb = double(fread(fid, 1, 'uint32'));
ultl_Cb = double(fread(fid, 1, 'uint32'));
sbytes_Cb = fread(fid, len_sbytes_Cb, 'uint32');
sbytes_Cb = double(sbytes_Cb);
% Obtenemos CodedCb original 
CodedCb=bytes2bits(sbytes_Cb, ultl_Cb); 

% CodedCr
len_sbytes_Cr = double(fread(fid, 1, 'uint32'));
ultl_Cr = double(fread(fid, 1, 'uint32'));
sbytes_Cr = fread(fid, len_sbytes_Cr, 'uint32');
sbytes_Cr = double(sbytes_Cr);
% Obtenemos CodedCR original 
CodedCr=bytes2bits(sbytes_Cr, ultl_Cr); 
% Close the file
fclose(fid);

% Decodifica los tres Scans a partir de strings binarios
XScanrec=DecodeScans_custom(CodedY,CodedCb,CodedCr,[mamp namp],BITS_Y_DC, HUFFVAL_Y_DC, BITS_Y_AC,HUFFVAL_Y_AC, BITS_C_DC,HUFFVAL_C_DC, BITS_C_AC, HUFFVAL_C_AC);

% Recupera matrices de etiquetas en orden natural
%  a partir de orden zigzag
Xlabrec=invscan(XScanrec);

% Descuantizacion de etiquetas
Xtransrec=desquantmat(Xlabrec, caliQ);

% Calcula iDCT bidimensional en bloques de 8 x 8 pixeles
% Como resultado, reconstruye una imagen YCbCr con tamaño ampliado
Xamprec = imidct(Xtransrec,m, n);

% Convierte a espacio de color RGB
% Para ycbcr2rgb: % Intervalo [0,255]->[0,1]->[0,255]
Xrecrd=round(ycbcr2rgb(Xamprec/255)*255);
Xrec=uint8(Xrecrd);

% Repone el tamaño original
Xrec=Xrec(1:m,1:n, 1:3);

% Guarda archivo descomprimido
imwrite(Xrec, nombrecomp, extension);

%Ya que la cabecera está compuesta por los datos n,m,namp,mamp y caliQ
%ocupará 4 bytes para cada uno de ellos
TAM_CAB = 4*5+(1+LEN_BITS_Y_DC)*4+(1+LEN_HUFFVAL_Y_DC)*4+(1+LEN_BITS_Y_AC)*4+(1+LEN_HUFFVAL_Y_AC)*4;
TAM_CAB = TAM_CAB+(1+LEN_BITS_C_DC)*4+(1+LEN_HUFFVAL_C_DC)*4+(1+LEN_BITS_C_AC)*4+(1+LEN_HUFFVAL_C_AC)*4;
TAM_DAT = length(U_SBYTES_Y)+ length(U_SBYTES_CB)+length(U_SBYTES_CR);
TC = TAM_CAB + TAM_DAT;

%Calculamos el error medio de la misma manera que indicaba la practica 4
MSE=(sum(sum(sum((double(Xrec)-double(XOR)).^2))))/(m*n*3);

%Calculamos RC
RC = 100*(TO-TC)/TO;

%Calculamos SNR
SNR = sum(sum(sum(double(XOR).^2)))/(sum(sum(sum((double(Xrec)-double(XOR)).^2))));
SNR = 10*log10(SNR);

% Test visual
if show
    [m,n,p] = size(XOR);
    figure('Units','pixels','Position',[100 100 n m]);
    set(gca,'Position',[0 0 1 1]);
    image(XOR); 
    set(gcf,'Name','Imagen original X');
    figure('Units','pixels','Position',[100 100 n m]);
    set(gca,'Position',[0 0 1 1]);
    image(Xrec);
    set(gcf,'Name','Imagen reconstruida Xrec');

end

end



