clear;
Original_image_dir  =    'C:/Users/csjunxu/Desktop/Projects/4000images/';
fpath = fullfile(Original_image_dir, '*.png');
im_dir  = dir(fpath);
im_num = length(im_dir);

%%
nSig = 50;
[par, model]  =  Parameters_Setting( nSig );
%%
for testcluster = 1:1:model.nmodels
    for c1 = [0.45 0.55]
        par.c1(testcluster,1) = c1;
        par.testcluster = testcluster;
        for delta = 0.06
            par.delta(1) = delta;
            for eta = 1
                par.eta(1) = eta;
                % record all the results in each iteration
                GPSNR = [];
                GSSIM = [];
                for i = 1:im_num
                    par.image = i;
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
                LPSNR = par.LPSNR(par.testcluster,:);
                LSSIM = par.LSSIM(par.testcluster,:);
                mLPSNR=mean(LPSNR);
                mLSSIM=mean(LSSIM);
                mGPSNR=mean(par.GPSNR);
                mGSSIM=mean(par.GSSIM);
                fprintf('The average PSNR = %2.4f, SSIM = %2.4f. \n', mGPSNR,mGSSIM);
                name = sprintf('WED1000_nSig%d_Cluster%d_delta%2.2f_c%2.2f_eta%2.2f.mat',nSig,par.testcluster,delta,c1,eta);
                save(name,'nSig','LPSNR','LSSIM','mLPSNR','mLSSIM','GPSNR','GSSIM','mGPSNR','mGSSIM');
            end
        end
    end
end