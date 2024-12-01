% Javier Polo Gambin - PCEO

% This script is used to test the performance of the Huffman encoders and decoders
% It uses the images in the folder ./Images/original/ and the caliQ factors defined in the array caliQ
% The resulting compressed images are stored in the folders ./Images/encoded_dflt/ and ./Images/encoded_custom/
% It computes the MSE, RC and SNR for each image and caliQ factor, and
% stores the results in the folder ./Data/<image_name>/ for its analysis later.


fprintf('Iniciando programa de testeo de los compresores Huffman\n');
fprintf('----------------------------------------------------------------------------\n\n');

close all;
clear;
clc;

orig_filepath = './Images/original/'; 
data_filepath = './Data/';
enc_dflt_filepath = './Images/encoded_dflt/';  
enc_custom_filepath = './Images/encoded_custom/';  

% Define the list of images and caliQ factor
orig_images = ["lena.bmp","mandrill.bmp","x-ray.bmp"];
caliQ = [5, 25, 50, 100, 200, 400, 750, 1000];

% Matrices to store the experimental data
% One for each parameter (MSE,RC,SNR,SSIM) and mode (DFLT,CUSTOM)
num_images = numel(orig_images);
num_caliQ = numel(caliQ);
MSE_DFLT = zeros(num_images, num_caliQ);
MSE_CUSTOM = zeros(num_images, num_caliQ);
RC_DFLT = zeros(num_images, num_caliQ);
RC_CUSTOM = zeros(num_images, num_caliQ);
SNR_DFLT = zeros(num_images, num_caliQ);
SNR_CUSTOM = zeros(num_images, num_caliQ);
SSIM_DFLT = zeros(num_images, num_caliQ);
SSIM_CUSTOM = zeros(num_images, num_caliQ);

t_global_ini = cputime;

% Loop through each image and compression level, and compute the compression rate and mean squared error
for img_idx = 1:num_images
    img = orig_images(img_idx);
    fprintf('Procesando %s\n', img);
    
    % Complete path to the file
    fname = fullfile(orig_filepath, img);
    [~, basename, ~] = fileparts(fname);
    
    for caliQ_idx = 1:num_caliQ
        caliQ_val = caliQ(caliQ_idx);
        
        %%% Default Compressor %%%
        fprintf('Procesando %s con caliQ = %.2f y el Compresor Huffman Default\n', img, caliQ_val);
        t_ini = cputime;
        % Compress the image
        jcom_dflt(fname, caliQ_val);
        % Decompress the image
        c_fname = fullfile(enc_dflt_filepath, strcat(basename, '_Q', num2str(caliQ_val), '_enc_dflt.hud'));
        [MSE_D, RC_D, SNR_D, SSIM_D] = jdes_dflt(c_fname, false);
        % Total CPU time
        t_total = cputime - t_ini;
        fprintf('TIEMPO TOTAL: %f \n', t_total);
        fprintf('--------------------------------------------------\n--------------------------------------------------\n');
        
        %%% Custom Compressor %%%
        fprintf('Procesando %s con caliQ = %.2f y el Compresor Huffman Custom\n', img, caliQ_val);
        t_ini = cputime;
        % Compress the image
        jcom_custom(fname, caliQ_val);
        % Decompress the image
        c_fname = fullfile(enc_custom_filepath, strcat(basename, '_Q', num2str(caliQ_val), '_enc_custom.huc'));
        [MSE_C, RC_C, SNR_C, SSIM_C] = jdes_custom(c_fname, false);
        % Total CPU time
        t_total = cputime - t_ini;
        fprintf('TIEMPO TOTAL: %f \n', t_total);
        fprintf('--------------------------------------------------\n--------------------------------------------------\n');
        
        % Store results in each matrix
        MSE_DFLT(img_idx, caliQ_idx) = MSE_D;
        MSE_CUSTOM(img_idx, caliQ_idx) = MSE_C;
        RC_DFLT(img_idx, caliQ_idx) = RC_D;
        RC_CUSTOM(img_idx, caliQ_idx) = RC_C;
        SNR_DFLT(img_idx, caliQ_idx) = SNR_D;
        SNR_CUSTOM(img_idx, caliQ_idx) = SNR_C;
        SSIM_DFLT(img_idx, caliQ_idx) = SSIM_D;
        SSIM_CUSTOM(img_idx, caliQ_idx) = SSIM_C;
    end
    
    % Data of each image each matrix stored in a different column
    img_DFLT = [caliQ', MSE_DFLT(img_idx, :)', RC_DFLT(img_idx, :)', SNR_DFLT(img_idx, :)', SSIM_DFLT(img_idx, :)'];
    img_CUSTOM = [caliQ', MSE_CUSTOM(img_idx, :)', RC_CUSTOM(img_idx, :)', SNR_CUSTOM(img_idx, :)', SSIM_CUSTOM(img_idx, :)'];
    img_data_folder = fullfile(data_filepath, basename);
    mkdir(img_data_folder);
    dlmwrite(fullfile(img_data_folder, strcat(basename, '_default.csv')), img_DFLT, 'delimiter', ';');
    dlmwrite(fullfile(img_data_folder, strcat(basename, '_custom.csv')), img_CUSTOM, 'delimiter', ';');
end

% total time
t_total = cputime - t_global_ini;
fprintf('\nTIEMPO TOTAL DEL PROGRAMA DE PRUEBAS: %.0f min, %.0f seg\n', floor(t_total/60), mod(t_total, 60));

fprintf('\nPrograma de pruebas finalizado\n\n');
