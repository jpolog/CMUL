close all
clear
clc

addpath('./auxiliar');
orig_filepath = '../Images/original/'; 
data_filepath = '../Data/';
enc_dflt_filepath = '../Images/encoded_dflt/';  
enc_custom_filepath = '../Images/encoded_custom/';  


% Define the list of images and caliQ factor

orig_images = ["graph.bmp","gradient.bmp","explorer.bmp","pattern.bmp","noise.bmp","cshapes.bmp","color_bars.bmp","candados.bmp","lennon.bmp","lena.bmp"];
%orig_images = ["graph.bmp","explorer.bmp","cshapes.bmp","candados.bmp","lennon.bmp","lena.bmp"];
%orig_images = ["color_bars.bmp","lena.bmp"];
caliQ = [5,25,50,100,175,250,500,1000];
%caliQ = [5];



% Matrices to store the experimental data
% One for each parameter (MSE,RC,SNR) and mode (DFLT,CUSTOM)
MSE_DFLT = [];
MSE_CUSTOM = [];
RC_DFLT = [];
RC_CUSTOM = [];
SNR_DFLT = [];
SNR_CUSTOM = [];

t_global_ini = cputime; 

% Loop through each image and compression level, and compute the compression rate and mean squared error
for img = orig_images    
    MSE_DFLT_COL = [];
    MSE_CUSTOM_COL = [];
    RC_DFLT_COL = [];
    RC_CUSTOM_COL = [];
    SNR_DFLT_COL = [];
    SNR_CUSTOM_COL = [];
    
    
    % Complete path to the file
    fname = strcat(orig_filepath, img);
    
    for j = 1:length(caliQ)
        %%% Default Compressor %%%
        fprintf('Processing %s with caliQ = %.2f and Custom Huffman compressor\n', img, caliQ(j));
        % time the whole process
        t_ini = cputime;
        % Compress the image
        jcom_dflt(fname, caliQ(j));
        % Decompress the image
        % Compressed file name
        [~,basename,~] = fileparts(fname);
        c_fname = strcat(enc_dflt_filepath, basename,'_Q',num2str(caliQ(j)),'_enc_dflt.hud');
        [MSE_D, RC_D, SNR_D] = jdes_dflt(c_fname,false);
        % Total CPU time
        t_total = cputime - t_ini;
        fprintf('\n---------------------------\nTIEMPO TOTAL: %f \n\n', t_total);
        
        %%% Compresor Custom %%%
        fprintf('Processing %s with caliQ = %.2f and Custom Huffman compressor\n', fname, caliQ(j));
        % time the whole process
        t_ini = cputime;
        % Compress the image
        jcom_custom(fname, caliQ(j));
        % Decompress the image
        c_fname = strcat(enc_custom_filepath, basename,'_Q',num2str(caliQ(j)),'_enc_custom.hud');
        [MSE_C, RC_C, SNR_C] = jdes_custom(c_fname,false);
        % Total CPU time
        t_total = cputime - t_ini;
        fprintf('\n---------------------------\nTIEMPO TOTAL: %f \n\n', t_total);
        
        % Store results in each matrix
        MSE_DFLT_COL = [MSE_DFLT_COL; MSE_D];
        MSE_CUSTOM_COL = [MSE_CUSTOM_COL; MSE_C];
        RC_DFLT_COL = [RC_DFLT_COL; RC_D];
        RC_CUSTOM_COL = [RC_CUSTOM_COL; RC_C];
        SNR_DFLT_COL = [SNR_DFLT_COL; SNR_D];
        SNR_CUSTOM_COL = [SNR_CUSTOM_COL; SNR_C];
        
        
    end
    MSE_DFLT = [MSE_DFLT, MSE_DFLT_COL];
    MSE_CUSTOM = [MSE_CUSTOM, MSE_CUSTOM_COL];
    RC_DFLT = [RC_DFLT, RC_DFLT_COL];
    RC_CUSTOM = [RC_CUSTOM, RC_CUSTOM_COL];
    SNR_DFLT = [SNR_DFLT, SNR_DFLT_COL];
    SNR_CUSTOM = [SNR_CUSTOM, SNR_CUSTOM_COL];
    
end


% write all data to files
dlmwrite(strcat(data_filepath,'MSE_default.csv'),MSE_DFLT,'delimiter', ';');
dlmwrite(strcat(data_filepath,'MSE_custom.csv'),MSE_CUSTOM, 'delimiter', ';');
dlmwrite(strcat(data_filepath,'RC_default.csv'),RC_DFLT,'delimiter', ';');
dlmwrite(strcat(data_filepath,'RC_custom.csv'),RC_CUSTOM,'delimiter', ';');
dlmwrite(strcat(data_filepath,'SNR_default.csv'),SNR_DFLT,'delimiter', ';');
dlmwrite(strcat(data_filepath,'SNR_custom.csv'),SNR_CUSTOM,'delimiter', ';');

% total time
t_total = cputime-t_global_ini;
fprintf('\n\nGLOBAL TIME: %f min', t_total/60);



