clear;
Original_image_dir  =    '../20images/';
fpath = fullfile(Original_image_dir, '*.png');
im_dir  = dir(fpath);
im_num = length(im_dir);

%%
nSig = 50;
[par, model]  =  Parameters_Setting( nSig );
eval(['load parc1_' num2str(nSig) '.mat']);
%%
index = false;
for IteNum = 2:1:4
    par.IteNum = IteNum;
    testcluster = 1;
    while testcluster <= model.nmodels
        par.testcluster = testcluster;
        mGPSNR = 0;
        mGSSIM = 0;
        for c1 = 0.01:0.01:1
            par.c1(testcluster, IteNum) = c1;
            % record all the results in each iteration
            GPSNR = [];
            GSSIM = [];
            for i = 1%:im_num
                par.image = i;
                par.nSig = nSig/255;
                par.I = single( imread(fullfile(Original_image_dir, im_dir(i).name)) )/255;
                S = regexp(im_dir(i).name, '\.', 'split');
                randn('seed',0);
                par.nim =   par.I + par.nSig*randn(size(par.I));
                fprintf('%s :\n',im_dir(i).name);
                fprintf('The initial value of PSNR = %2.4f, SSIM = %2.4f \n', csnr( par.nim*255, par.I*255, 0, 0 ),cal_ssim( par.nim*255, par.I*255, 0, 0 ));
                %%
                [im_out,par]  =  PGPD_DenoiserLearning(par,model);
                % calculate the PSNR
                GPSNR = [GPSNR  csnr( im_out*255, par.I*255, 0, 0 )];
                GSSIM =  [GSSIM cal_ssim( im_out*255, par.I*255, 0, 0 )];
                %                                 imname = sprintf('PGPD_nSig%d_%s',nSig,im_dir(i).name);
                %                                 imwrite(im_out,imname);
                fprintf('%s : PSNR = %2.4f, SSIM = %2.4f \n',im_dir(i).name, csnr( im_out*255, par.I*255, 0, 0 ), cal_ssim( im_out*255, par.I*255, 0, 0 ) );
            end
            fprintf('Cluster %d:\n', par.testcluster);
            mGPSNR = [mGPSNR mean(par.GPSNR(IteNum,:))];
            mGSSIM = [mGSSIM mean(par.GSSIM(IteNum,:))];
            mGPSNRend = mGPSNR(end);
            mGSSIMend = mGSSIM(end);
            fprintf('The average PSNR = %2.4f, SSIM = %2.4f. \n', mGPSNR(end), mGSSIM(end));
            name = sprintf('nSig%d_IteNum%d_cluster%d_c%2.2f.mat',nSig,IteNum,testcluster,c1);
            save(name,'nSig','GPSNR','GSSIM','mGPSNR','mGSSIM','mGPSNRend','mGSSIMend');
        end
        if abs(mGPSNR(end) - mGPSNR(end - 1)) < 1e-4
            name = sprintf('par_c1_%d.mat',nSig);
            save(name,'par');
            testcluster = testcluster + 1;
        end
    end
end