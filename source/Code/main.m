close all
clear
clc

addpath('./auxiliar');
orig_filepath = '../Images/original/'; 
data_filepath = '../Data/';
enc_dflt_filepath = '../Images/encoded_dflt/';  
enc_custom_filepath = '../Images/encoded_custom/';  


% Define the list of images and caliQ factor

%orig_images = ["graph.bmp","gradient.bmp","explorer.bmp","pattern.bmp","triangles.bmp","cshapes.bmp","color_bars.bmp","candados.bmp","lennon.bmp","lena.bmp"];
%orig_images = ["graph.bmp","explorer.bmp","cshapes.bmp","candados.bmp","lennon.bmp","lena.bmp"];
orig_images = ["color_bars.bmp"];
%caliQ = [5,25,50,100,250,500,750,1000];
caliQ = [5,25,50,100];


% write each image name as a string separated by commas in each output file
for i = 1:length(orig_images)
    if i == 1
        fidMSE_D = fopen(strcat(data_filepath,'MSE_default.csv'),'w');
        fidMSE_C = fopen(strcat(data_filepath,'MSE_custom.csv'),'w');
        fidRC_D = fopen(strcat(data_filepath,'RC_default.csv'),'w');
        fidRC_C = fopen(strcat(data_filepath,'RC_custom.csv'),'w');
        fidSNR_D = fopen(strcat(data_filepath,'SNR_default.csv'),'w');
        fidSNR_C = fopen(strcat(data_filepath,'SNR_custom.csv'),'w');
    end
    if i == length(orig_images)
        fprintf(fidMSE_D,'%s',orig_images(i));
        fprintf(fidMSE_C,'%s',orig_images(i));
        fprintf(fidRC_D,'%s',orig_images(i));
        fprintf(fidRC_C,'%s',orig_images(i));
        fprintf(fidSNR_D,'%s',orig_images(i));
        fprintf(fidSNR_C,'%s',orig_images(i));
        fclose(fidMSE_D);
        fclose(fidMSE_C);
        fclose(fidRC_D);
        fclose(fidRC_C);
        fclose(fidSNR_D);
        fclose(fidSNR_C);
    else
        fprintf(fidMSE_D,'%s,',orig_images(i));
        fprintf(fidMSE_C,'%s,',orig_images(i));
        fprintf(fidRC_D,'%s,',orig_images(i));
        fprintf(fidRC_C,'%s,',orig_images(i));
        fprintf(fidSNR_D,'%s,',orig_images(i));
        fprintf(fidSNR_C,'%s,',orig_images(i));
    end
end



% Matrices to store the experimental data
% One for each parameter (MSE,RC,SNR) and mode (DFLT,CUSTOM)
MSE_DFLT = [];
MSE_CUSTOM = [];
RC_DFLT = [];
RC_CUSTOM = [];
SNR_DFLT = [];
SNR_CUSTOM = [];


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
dlmwrite(strcat(data_filepath,'MSE_default.csv'),MSE_DFLT,'delimiter', ',','roffset',1, '-append');
dlmwrite(strcat(data_filepath,'MSE_custom.csv'),MSE_CUSTOM, 'delimiter', ',', 'roffset',1, '-append');
dlmwrite(strcat(data_filepath,'RC_default.csv'),RC_DFLT,'delimiter', ',', 'roffset',1, '-append');
dlmwrite(strcat(data_filepath,'RC_custom.csv'),RC_CUSTOM,'delimiter', ',', 'roffset',1, '-append');
dlmwrite(strcat(data_filepath,'SNR_default.csv'),SNR_DFLT,'delimiter', ',', 'roffset',1, '-append');
dlmwrite(strcat(data_filepath,'SNR_custom.csv'),SNR_CUSTOM,'delimiter', ',', 'roffset',1, '-append');





