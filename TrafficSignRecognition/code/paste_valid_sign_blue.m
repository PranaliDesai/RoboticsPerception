function [chosen_bbox_arr, im, pos_train_ind_arr] = paste_valid_sign_blue(bbox, im, classifier, sign_pos_arr, cell_size, max_error_score, size_train_image, right_pos_taken)
% Function to remove false postives in traffic sign recognition by querying
% the classifier
% Input -> bbox - a n x 4 array of dimension of bounding box
%          im - Original Image
%          classifier - classifer obtained from multi-class SVM training
%          sign_pos_arr - 2 x 4 array describing position where to paste
%          the detected sign
%          cell_size - cell size for HOG features
%          max_error_score - max permissible error for positive sign
%          detection
%          size_train_image - size of the training image to be used for
%          pasting
%          right_pos_taken - A boolean indicating whether right position
%          has already been taken by some other traffic sign identification
%Output -> chosen_bbox_arr - A 1 x 4 or empty array giving the dimensions
%           of bounding box
%         im - Original Image returned after pasting the identified
%               traffic sign
%         pos_train_ind_arr - An array indicating the psosition of pasted
%         sign
iter = size(bbox,1);
chosen_bbox = 0;
chosen_bbox_arr = [];
im_gray = rgb2gray(im);
%right_pos_taken = false;
pos_train_ind_arr = [];
for j = 1:iter
   if chosen_bbox == 2
       break;   % Focus on only two traffic signs max in a single frame
   end
   curr_bbox = bbox(j,:);
   im_roi = imcrop(im_gray, curr_bbox);
   im_roi = imresize(im_roi, [64,64]);
   %% Find the sign
   hog = vl_hog(im2single(im_roi), cell_size,'variant', 'dalaltriggs') ;
   testFeatures = hog(:)';
   [predictedLabel, scores] = predict(classifier, testFeatures);
   if min(abs(scores)) > max_error_score
       continue;
   end
   % HACK for Red - No red signs be detected in blue sign area
       [~, min_error_ind] = min(abs(scores));
       if min_error_ind <= 5
           continue;
       end
   %% Paste the image at appropriate locations in the image
   chosen_bbox_arr = [chosen_bbox_arr;curr_bbox];
   label_name = cellstr(predictedLabel);
   label_folder = cell2mat(fullfile('..\training\subset_training', label_name));
   D = dir([label_folder,'\*.ppm']);
   fullfilename = fullfile(label_folder,D(1).name);
   im_train = imread(fullfilename);
   im_train = imresize(im_train,[size_train_image size_train_image]);
   if (curr_bbox(1) > (size(im,2) / 2) && ~right_pos_taken)
       pos_train_ind = 2;
       right_pos_taken = true;
   else
       pos_train_ind = 1;
   end
   pos_train_ind_arr = [pos_train_ind_arr; pos_train_ind];  
   rect = sign_pos_arr(pos_train_ind,:);
   for colorplane = 1 :3
    im(rect(1):rect(2), rect(3):rect(4), colorplane) = 0.1 * im(rect(1):rect(2), rect(3):rect(4), colorplane) + ...
        0.9 * im_train(:,:,colorplane);
   end
   chosen_bbox = chosen_bbox + 1;
end
end