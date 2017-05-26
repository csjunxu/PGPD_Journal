clear;
Original_image_dir  =    'C:\Users\csjunxu\Desktop\Projects\WODL\20images\';
fpath = fullfile(Original_image_dir, '*.png');
im_dir  = dir(fpath);
im_num = length(im_dir);

nSig = 50;
% set parameters
[Par, model]  =  Parameters_Setting( nSig );
% record all the results in each iteration
PSNR = [];
SSIM = [];
Par.delta = 0.06;


Par.c1= 0.46;
Par.eta = 1;
for i = 1:im_num
    Par.image = i;
    Par.I = single( imread(fullfile(Original_image_dir, im_dir(i).name)) )/255;
    S = regexp(im_dir(i).name, '\.', 'split');
    randn('seed',0);
    Par.nim =   Par.I + Par.nSig*randn(size(Par.I));
    fprintf('%s :\n',im_dir(i).name);
    fprintf('The initial value of PSNR = %2.4f, SSIM = %2.4f \n', csnr( Par.nim*255, Par.I*255, 0, 0 ),cal_ssim( Par.nim*255, Par.I*255, 0, 0 ));
    %%
    [im_out,Par]  =  PGPD_Denoising(Par,model);
    % calculate the PSNR
    PSNR = [PSNR  csnr( im_out*255, Par.I*255, 0, 0 )];
    SSIM =  [SSIM cal_ssim( im_out*255, Par.I*255, 0, 0 )];
    %                                 imname = sprintf('PGPD_nSig%d_%s',nSig,im_dir(i).name);
    %                                 imwrite(im_out,imname);
    fprintf('%s : PSNR = %2.4f, SSIM = %2.4f \n',im_dir(i).name, csnr( im_out*255, Par.I*255, 0, 0 ), cal_ssim( im_out*255, Par.I*255, 0, 0 ) );
end
mPSNR=mean(PSNR);
mSSIM=mean(SSIM);
fprintf('The average PSNR = %2.4f, SSIM = %2.4f. \n', mPSNR,mSSIM);
name = sprintf('PGPD_nSig%d_1.mat',nSig);
save(name,'nSig','PSNR','SSIM','mPSNR','mSSIM');
