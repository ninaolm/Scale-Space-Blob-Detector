function [ scaleSpace ] = generateScaleSpace( img_GrayScale, numScales, sigma, scaleMultiplier, bShouldDownsample )
%GENERATESCALESPACE Summary of this function goes here
%   Detailed explanation goes here

    [h,w] = size(img_GrayScale);
    scaleSpace = zeros(h, w, numScales); % structure to hold the scale space 

    %Applying the kernel filter is all about relative size (between the 
    %kernel and the image). Conceptually we want to increase the kernel
    %size and reapply it to the image to generate the different scales.
    %But it is relatively inefficient to repeatedly filter the image with  
    %a kernel of increasing size. Instead of increasing the kernel size by 
    %a factor of k, simply downsample the image by a factor 1/k and apply
    %the same kernel. Of course after applying the kernel, the result the
    %result has to be upsampled.

    if bShouldDownsample
        % Process will be... don't change filter size, but downsize the image 
        %by 1/k, filter with same kernel, and then rescale/upsize back

        %-------- Generate just 1 normalized filter (min size 1x1)-------------
        %(borrowed mostly from "http://slazebni.cs.illinois.edu/spring16/harris.m")
        kernelSize = max(1,fix(6*sigma)+1);  %+1 to guarantee odd filter size
        % Create a Laplacian of Gaussian kernel ('log')
        LoGKernel = fspecial( 'log', kernelSize, sigma );
        % Nomrmalize the kernel 
        LoGKernel = sigma.^2 * LoGKernel;

        reUpscaledImg = zeros(h,w);
        downsizedImg = img_GrayScale;


        for i = 1:numScales
            % Downsize the image by 1/k... use bicubic instead of bilinear to
            % keep spatial resolution. Here k is the scaleMultiplicationConstant
            if i==1
                downsizedImg = img_GrayScale;
            else
                downsizedImg = imresize(img_GrayScale, 1/(scaleMultiplier^(i-1)), 'bicubic');
            end
            % Filter the image to generate a response to the laplacian of
            % gaussian 
            filteredImage = imfilter(downsizedImg, LoGKernel,'same', 'replicate');
            %Save square of Laplacian response for current level of scale space
            filteredImage = filteredImage .^ 2;

            % Upscale the filter response
            reUpscaledImg = imresize(filteredImage, [h,w], 'bicubic');
            % Store it at the appropriate level in the scale space
            scaleSpace(:,:,i) = reUpscaledImg;
        end
    else
        %increase the kernel size and reapply it to the image 
        %to generate the different scales.
        for i = 1:numScales
            %--Calculate a new sigma, and regenerate the kernel for each scale
            scaledSigma = sigma * scaleMultiplier^(i-1);
            kernelSize = max(1,fix(6*scaledSigma)+1);  %+1 to guarantee odd filter size
            % Create a Laplacian of Gaussian kernel ('log')
            LoGKernel = fspecial( 'log', kernelSize, scaledSigma );
            % Nomrmalize the kernel 
            LoGKernel = scaledSigma.^2 * LoGKernel;      

            % Filter the image to generate a response to the laplacian of
            % gaussian 
            filteredImage = imfilter(img_GrayScale, LoGKernel,'same', 'replicate');
            % Save square of Laplacian response for current level of scale space
            filteredImage = filteredImage .^ 2;

            % Store it at the appropriate level in the scale space
            scaleSpace(:,:,i) = filteredImage;     
        end
    end

end
