function [MSE, RC, SNR] = jdes_dflt(fname, extension, show)








% Open the compressed file
fid = fopen(fname,'r');



% Verbosity flag
vflag = 1;
if vflag
    fprintf('Decompressing %s using default Huffman tables...\n\n', fname);
end


% Leemos los parámetros de la imagen original
n= double(fread(fid, 1, 'uint32'));    
namp= double(fread(fid, 1, 'uint32'));  
m= double(fread(fid, 1, 'uint32'));    
mamp= double(fread(fid, 1, 'uint32'));   
caliQ= double(fread(fid, 1, 'uint32')); 

% CodedY
len_sbytes_Y = double(fread(fid, 1, 'uint32'));
ultl_Y = double(fread(fid, 1, 'uint32'));
sbytes_Y = fread(fid, len_sbytes_Y, 'uint32');
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Decode 3 scans from binary strings %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
XScanrec=DecodeScans_dflt(CodedY,CodedCb,CodedCr,[mamp namp]);

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
%%%> When using ycbcr2rgb 
%%%> Output image in RGB will have values in range [0,1].
%%%> we have to scale the values to [0,1] before converting
Xrecrd=round(ycbcr2rgb(Xamprec/255)*255);
Xrec=uint8(Xrecrd);

% Repone el tamaño original
Xrec=Xrec(1:m,1:n, 1:3);

% Genera nombre archivo descomprimido <nombre>_des.bmp
%[pathstr,name,ext] = fileparts(fname);
%nombrecomp=strcat(name,'_des_def','.bmp');

% Guarda archivo descomprimido
imwrite(Xrec,nombrecomp,extension);

%Ya que la cabecera est´s compuesta por los datos n,m,namp,mamp y caliQ
%ocupará 4 bytes para cada uno de ellos
TAM_CAB = 4*5;
TAM_DAT = length(sbytes_Y)+ length(sbytes_Cb)+length(sbytes_Cr);
TC = TAM_CAB + TAM_DAT;

%Calculamos el MSE
MSE=(sum(sum(sum((double(Xrec)-double(XOR)).^2))))/(m*n*3);

%Calculamos RC
RC = 100*(TO-TAM_DAT)/TO;

%Calculamos SNR
SNR = sum(sum(sum(double(XOR).^2)))/(sum(sum(sum((double(Xrec)-double(XOR)).^2))));
SNR = 10*log10(SNR);

% Test visual
if show
    [m,n,~] = size(XOR);
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