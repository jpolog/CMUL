close all
clear
clc

addpath('./auxiliar');

% Define the list of images and caliQ to test
%images = {'images/lena.bmp', 'images/lennon.bmp', 'images/cshapes.bmp'};
images = ["../Images/original/Img03.bmp"];
caliQ = [100];

% Loop through each image and compression level, and compute the compression rate and mean squared error
for img = images
    for j = 1:length(caliQ)
        %%% Compresor Default %%%
        fprintf('Processing %s with caliQ = %.2f and Custom Huffman compressor\n', img, caliQ(j));
        % time the whole process
        t_ini = cputime;
        % Compress the image
        jcom_custom(img, caliQ(j));
        % Decompress the image
        [MSE_C, RC_C, SNR_C] = jdes_custom(img);
        % Total CPU time
        t_total = cputime - t_ini;
        fprintf('\n---------------------------\nTIEMPO TOTAL: %f \n\n', t_total);
        
        %%% Compresor Custom %%%
        fprintf('Processing %s with caliQ = %.2f and Custom Huffman compressor\n', img, caliQ(j));
        % time the whole process
        t_ini = cputime;
        % Compress the image
        jcom_dflt(img, caliQ(j));
        % Decompress the image
        [MSE_D, RC_D, SNR_D] = jdes_dflt(img);
        % Total CPU time
        t_total = cputime - t_ini;
        fprintf('\n---------------------------\nTIEMPO TOTAL: %f \n\n', t_total);
        
        % Write the results to a file
        fid = fopen('results.txt', 'a');
        fprintf(fid,'CUSTOM\n');
        fprintf(fid, 'IMG:%s\n\t%.2f\n\t%f\n\t%f\n\t%f\n\t%f\n', img, caliQ(j),MSE_C, RC_C, SNR_C);
        fprintf(fid,'DEFAULT\n');
        fprintf(fid, 'IMG:%s\n\t%.2f\n\t%f\n\t%f\n\t%f\n\t%f\n', img, caliQ(j),MSE_D, RC_D, SNR_D);
        fprintf(fid, '\n\n\n---------------------------\n\n\n');
        fclose(fid);
        
    end
end



function [MSE, RC, SNR] = compress_decompress(fname, caliQ, compressor_type)
    if compressor_type == 0
        compressor = @jcom_dflt;
        decompressor = @jdes_dflt;
    elseif compressor_type == 1
        compressor = @jcom_custom;
        decompressor = @jdes_custom;
    else
        error('Invalid compressor type');
    end
    % time the whole process
    t_ini = cputime;
    % Compress the image
    compressor(fname, caliQ);
    % Total CPU time
    t_total = cputime - t_ini;
    % Decompress the image
    
    [MSE, RC, SNR] = decompressor(fname);
    fprintf('\n---------------------------\nTIEMPO TOTAL: %f \n\n', t_total);
end