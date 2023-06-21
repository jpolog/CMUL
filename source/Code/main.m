% Javier Polo Gambin - PCEO

% This script is used to test the performance of the Huffman encoders and decoders
% It uses the images in the folder ../Images/original/ and the caliQ factors defined in the array caliQ
% The resulting compressed images are stored in the folders ../Images/encoded_dflt/ and ../Images/encoded_custom/
% It computes the MSE, RC and SNR for each image and caliQ factor, and stores the results in the folder ../Data/<image_name>/

fprintf('Iniciando programa de testeo de los compresores Huffman\n')
fprintf('----------------------------------------------------------------------------\n\n')

close all
clear
clc

addpath('./auxiliar');
orig_filepath = '../Images/original/'; 
data_filepath = '../Data/';
enc_dflt_filepath = '../Images/encoded_dflt/';  
enc_custom_filepath = '../Images/encoded_custom/';  


% Define the list of images and caliQ factor

orig_images = ["graph.bmp","gradient.bmp","explorer.bmp","pattern.bmp","noise.bmp","cshapes.bmp","color_lines.bmp","candados.bmp","lennon.bmp","lena.bmp"];
caliQ = [5,25,50,100,175,250,500,1000];



% Matrices to store the experimental data
% One for each parameter (MSE,RC,SNR,SSIM) and mode (DFLT,CUSTOM)
MSE_DFLT = [];
MSE_CUSTOM = [];
RC_DFLT = [];
RC_CUSTOM = [];
SNR_DFLT = [];
SNR_CUSTOM = [];
SSIM_DFLT = [];
SSIM_CUSTOM = [];

t_global_ini = cputime; 

% Loop through each image and compression level, and compute the compression rate and mean squared error
for img = orig_images    
    MSE_DFLT_COL = [];
    MSE_CUSTOM_COL = [];
    RC_DFLT_COL = [];
    RC_CUSTOM_COL = [];
    SNR_DFLT_COL = [];
    SNR_CUSTOM_COL = [];
    SSIM_DFLT_COL = [];
    SSIM_CUSTOM_COL = [];
    
    
    % Complete path to the file
    fname = strcat(orig_filepath, img);
    
    for j = 1:length(caliQ)
        %%% Default Compressor %%%
        fprintf('Procesando %s con caliQ = %.2f y el Compresor Huffman Default\n', img, caliQ(j));
        % time the whole process
        t_ini = cputime;
        % Compress the image
        jcom_dflt(fname, caliQ(j));
        % Decompress the image
        % Compressed file name
        [~,basename,~] = fileparts(fname);
        c_fname = strcat(enc_dflt_filepath, basename,'_Q',num2str(caliQ(j)),'_enc_dflt.hud');
        [MSE_D, RC_D, SNR_D, SSIM_D] = jdes_dflt(c_fname,false);
        % Total CPU time
        t_total = cputime - t_ini;
        fprintf('TIEMPO TOTAL - : %f \n', t_total);
        fprintf('--------------------------------------------------\n--------------------------------------------------\n');
        
        %%% Compresor Custom %%%
        fprintf('Procesando %s con caliQ = %.2f y el Compresor Huffman Custom\n', img, caliQ(j));
        % time the whole process
        t_ini = cputime;
        % Compress the image
        jcom_custom(fname, caliQ(j));
        % Decompress the image
        c_fname = strcat(enc_custom_filepath, basename,'_Q',num2str(caliQ(j)),'_enc_custom.hud');
        [MSE_C, RC_C, SNR_C, SSIM_C] = jdes_custom(c_fname,false);
        % Total CPU time
        t_total = cputime - t_ini;
        fprintf('TIEMPO TOTAL: %f \n', t_total);
        fprintf('--------------------------------------------------\n--------------------------------------------------\n');
        
        % Store results in each matrix
        MSE_DFLT_COL = [MSE_DFLT_COL; MSE_D];
        MSE_CUSTOM_COL = [MSE_CUSTOM_COL; MSE_C];
        RC_DFLT_COL = [RC_DFLT_COL; RC_D];
        RC_CUSTOM_COL = [RC_CUSTOM_COL; RC_C];
        SNR_DFLT_COL = [SNR_DFLT_COL; SNR_D];
        SNR_CUSTOM_COL = [SNR_CUSTOM_COL; SNR_C];
        SSIM_DFLT_COL = [SSIM_DFLT_COL; SSIM_D];
        SSIM_CUSTOM_COL = [SSIM_CUSTOM_COL; SSIM_C];
        
        
    end
    % Data of each image
    img_DFLT = [MSE_DFLT_COL,RC_DFLT_COL,SNR_DFLT_COL,SSIM_DFLT_COL];
    img_CUSTOM = [MSE_CUSTOM_COL,RC_CUSTOM_COL,SNR_CUSTOM_COL,SSIM_CUSTOM_COL];
    dlmwrite(strcat(data_filepath,basename,'/',basename,'_default.csv'),img_DFLT,'delimiter', ';');
    dlmwrite(strcat(data_filepath,basename,'/',basename,'_custom.csv'),img_CUSTOM,'delimiter', ';');
    
    % Global Data of all images
    MSE_DFLT = [MSE_DFLT, MSE_DFLT_COL];
    MSE_CUSTOM = [MSE_CUSTOM, MSE_CUSTOM_COL];
    RC_DFLT = [RC_DFLT, RC_DFLT_COL];
    RC_CUSTOM = [RC_CUSTOM, RC_CUSTOM_COL];
    SNR_DFLT = [SNR_DFLT, SNR_DFLT_COL];
    SNR_CUSTOM = [SNR_CUSTOM, SNR_CUSTOM_COL];
    SSIM_DFLT = [SSIM_DFLT, SSIM_DFLT_COL];
    SSIM_CUSTOM = [SSIM_CUSTOM, SSIM_CUSTOM_COL];
    
end


% write all data to files
dlmwrite(strcat(data_filepath,'MSE_default.csv'),MSE_DFLT,'delimiter', ';');
dlmwrite(strcat(data_filepath,'MSE_custom.csv'),MSE_CUSTOM, 'delimiter', ';');
dlmwrite(strcat(data_filepath,'RC_default.csv'),RC_DFLT,'delimiter', ';');
dlmwrite(strcat(data_filepath,'RC_custom.csv'),RC_CUSTOM,'delimiter', ';');
dlmwrite(strcat(data_filepath,'SNR_default.csv'),SNR_DFLT,'delimiter', ';');
dlmwrite(strcat(data_filepath,'SNR_custom.csv'),SNR_CUSTOM,'delimiter', ';');
dlmwrite(strcat(data_filepath,'SSIM_default.csv'),SSIM_DFLT,'delimiter', ';');
dlmwrite(strcat(data_filepath,'SSIM_custom.csv'),SSIM_CUSTOM,'delimiter', ';');

% total time
t_total = cputime-t_global_ini;
fprintf('\n\nTIEMPO TOTAL DEL PROGRAMA DE PRUEBAS: %f min, %f seg', t_total/60, mod(t_total,60));

fprintf('\n\nPrograma de pruebas finalizado\n\n')


