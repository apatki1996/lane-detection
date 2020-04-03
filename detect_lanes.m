function [rho1, theta1, rho2, theta2] = detect_lanes(img)

% Caltech lanes dataset.
% Caltech Lanes dataset includes four clips taken around streets in Pasadena, CA at different times of day.
% The archive below inlucdes 1225 individual frames as taken from a camera mounted on Alice in addition to the labeled lanes. 
% The dataset is divided into four individual clips: cordova1 with 250 
% frames, cordova2 with 406 frames, washington1 with 337 frames, and washington2 with 232 frames.
% 250, 232 images with ground truth. [rho1, theta1, rho2, theta2]

% Cases where it failed, Traffic lights and Zebra crossings
% Shadows on the roads. Sidewalks and palm trees.

% ROI and Morphological operations
% edge detection
% hough lines
% function to find the closest lines

    gray_img = rgb2gray(img);
    
    
    % to reduce the noise in the image    
    gray_img = imgaussfilt(gray_img, 2);        
    edge_img = edge(gray_img, 'canny', 0.2);
    
    % Region of interest, trial-and-error. View blocked by lens and sensors installed on the car
    % Trapezoidal ROI, masked the unnecessary parts of the image
    mask = roipoly(edge_img, [280, 360, 510, 180], [176, 176, 325, 325]);
    edge_img = edge_img .* mask;

    % remove small areas
    % bwareaopen removes all connected components (objects) that have fewer than P pixels from the binary image
    edge_img = bwareaopen(edge_img, 30);
    
    % perform morphological close
    % lines of the lane at an approximate angle of 45 degrees.
    % Morphological operations process the image based on the shape
    % In a morphological operation, the value of each pixel in the output image is based on
    % a comparison of the corresponding pixel in the input image with its neighbors.
    
    % Morphological operations apply a structuring element to an input image
    % Morphological DILATION makes objects more visible and fills in small holes in objects.
    % Morphological EROSION removes islands and small objects so that only substantive objects remain.
    % Morphological OPENing is useful for removing small objects from an image while preserving the 
    % shape and size of larger objects in the image. Erodes then dilates
    % Morphological CLOSing is useful for filling small holes from an image while preserving the
    % shape and size of the objects in the image. Dilates then erodes
    
    % Structuring element is the matrix determines which neighboring pixels are used for processing
    % around a particular pixel
    SE_l = strel('line', 20, -45);
    edge_img = imclose(edge_img, SE_l);

    SE_r = strel('line', 20, 45);
    edge_img = imclose(edge_img, SE_r);
    
    % Edge detection, Sobel
    % Gradient in x and y and combined
    
    % Split the image into two halves
    edge_img_left = edge_img;
    edge_img_right = edge_img;

    % mask right side
    edge_img_left(:,size(edge_img,2)/2:size(edge_img,2),:) = 0;
    
    % mask left side
    edge_img_right(:,1:size(edge_img,2)/2,:) = 0;
    
    [H_l,T_l,R_l] = hough(edge_img_left, 'Theta', 20:50);
    [H_r,T_r,R_r] = hough(edge_img_right, 'Theta', -50:-20);
    
    P_l = houghpeaks(H_l,5,'threshold',ceil(0.3*max(H_l(:))));
    P_r = houghpeaks(H_r,5,'threshold',ceil(0.3*max(H_r(:))));
    
    lines_left = houghlines(edge_img_left,T_l,R_l,P_l,'FillGap',300,'MinLength',35);
    lines_right = houghlines(edge_img_right,T_r,R_r,P_r,'FillGap',300,'MinLength',10);
    
    theta1 = pi / 4;
    rho1 = 300;
    theta2 = -10000;
    rho2 = 100;
    
    for k = 1:length(lines_left)
        if theta1 < lines_left(k).theta
            theta1 = lines_left(k).theta;
            theta1 = deg2rad(theta1);
            rho1 = lines_left(k).rho;
        end
    end
    
    for k = 1:length(lines_right)
       if theta2 < lines_right(k).theta
            theta2 = lines_right(k).theta;
            theta2 = deg2rad(theta2);
            rho2 = lines_right(k).rho;
       end
    end


%     rho1 = 300;
%     theta1 = pi/4;
%     rho2 = 100;
%     theta2 = -pi / 4;



end
