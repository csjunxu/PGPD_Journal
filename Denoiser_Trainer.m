function Denoiser_Trainer(model, par, nSig, IteNum, testcluster, c1, cstep, mGPSNR, mGSSIM)

im_dir  = dir(par.fpath);
im_num = min(length(im_dir), 100);

eval(['load ' par.TD '_param_c1_' num2str(nSig) '.mat']);
par.c1 = param_c1;
par.testcluster = testcluster;

index = false;
while ~index
    c1 = c1 + cstep;
    par.c1(testcluster, IteNum) = c1;
    fprintf('IteNum = %d, testcluster = %d, c1 = %2.2f. \n', IteNum, testcluster, c1);
    % record all the results in each iteration
    GPSNR = [];
    GSSIM = [];
    for i = 1:im_num
        par.image = i;
        par.nSig = nSig/255;
        par.I = double( imread(fullfile(par.Original_image_dir, im_dir(i).name)) )/255;
        %         S = regexp(im_dir(i).name, '\.', 'split');
        randn('seed',0);
        par.nim = par.I + par.nSig*randn(size(par.I));
        fprintf('%s :\n',im_dir(i).name);
        fprintf('The initial value of PSNR = %2.4f, SSIM = %2.4f \n', csnr( par.nim*255, par.I*255, 0, 0 ),cal_ssim( par.nim*255, par.I*255, 0, 0 ));
        %%
        [im_out,par]  =  PGPD_DenoiserLearning(par,model);
        %% calculate the PSNR
        GPSNR = [GPSNR  csnr( im_out*255, par.I*255, 0, 0 )];
        GSSIM =  [GSSIM cal_ssim( im_out*255, par.I*255, 0, 0 )];
        % imname = sprintf('PGPD_nSig%d_%s',nSig,im_dir(i).name);
        % imwrite(im_out,imname);
        fprintf('%s : PSNR = %2.4f, SSIM = %2.4f \n', im_dir(i).name, csnr( im_out*255, par.I*255, 0, 0 ), cal_ssim( im_out*255, par.I*255, 0, 0 ) );
    end
    fprintf('Cluster %d:\n', par.testcluster);
    mGPSNR = [mGPSNR mean(GPSNR)];
    mGSSIM = [mGSSIM mean(GSSIM)];
    mGPSNRend = mGPSNR(end);
    mGSSIMend = mGSSIM(end);
    fprintf('The average PSNR = %2.4f, SSIM = %2.4f. \n', mGPSNR(end), mGSSIM(end));
    name = sprintf('%s/%d_nSig%d_IteNum%d_cluster%d_c%2.2f.mat', par.TD, im_num, nSig, IteNum, testcluster, c1);
    save(name, 'nSig', 'GPSNR', 'GSSIM', 'mGPSNR', 'mGSSIM', 'mGPSNRend', 'mGSSIMend');
    if abs(mGPSNR(end) - mGPSNR(end - 1))< 1e-5
        name = sprintf('%s_param_c1_%d.mat', par.TD, nSig);
        param_c1 = par.c1;
        save(name, 'param_c1');
        index = true;
        break;
    end
end
