clear;
Original_image_dir  =    '../20images/';
fpath = fullfile(Original_image_dir, '*.png');
im_dir  = dir(fpath);
im_num = length(im_dir);
nSig = 50;
% set parameters
[par, model]  =  Parameters_Setting( nSig );
% record all the results in each iteration
PSNR = [];
SSIM = [];
par.c1= 0.46;
par.delta = 0.06;
par.eta = 1;
for i = 1:im_num
    par.image = i;
    par.I = single( imread(fullfile(Original_image_dir, im_dir(i).name)) )/255;
    S = regexp(im_dir(i).name, '\.', 'split');
    randn('seed',0);
    par.nim =   par.I + par.nSig*randn(size(par.I));
    fprintf('%s :\n',im_dir(i).name);
    fprintf('The initial value of PSNR = %2.4f, SSIM = %2.4f \n', csnr( par.nim*255, par.I*255, 0, 0 ),cal_ssim( par.nim*255, par.I*255, 0, 0 ));
    %%
    [im_out,par]  =  PGPD_Denoising(par,model);
    % calculate the PSNR
    PSNR = [PSNR  csnr( im_out*255, par.I*255, 0, 0 )];
    SSIM =  [SSIM cal_ssim( im_out*255, par.I*255, 0, 0 )];
    %                                 imname = sprintf('PGPD_nSig%d_%s',nSig,im_dir(i).name);
    %                                 imwrite(im_out,imname);
    fprintf('%s : PSNR = %2.4f, SSIM = %2.4f \n',im_dir(i).name, csnr( im_out*255, par.I*255, 0, 0 ), cal_ssim( im_out*255, par.I*255, 0, 0 ) );
end
mPSNR=mean(PSNR);
mSSIM=mean(SSIM);
fprintf('The average PSNR = %2.4f, SSIM = %2.4f. \n', mPSNR,mSSIM);
name = sprintf('PGPD_nSig%d_1.mat',nSig);
save(name,'nSig','PSNR','SSIM','mPSNR','mSSIM');
