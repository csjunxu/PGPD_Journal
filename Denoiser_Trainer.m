clear;
Original_image_dir  =    '../20images/';
fpath = fullfile(Original_image_dir, '*.png');
im_dir  = dir(fpath);
im_num = length(im_dir);

%%
nSig = 50;
[par, model]  =  Parameters_Setting( nSig );
par.c1(1,1) = 0.44;
par.c1(2,1) = 0.85;
par.c1(3,1) = 0.40;
par.c1(4,1) = 0.47;
par.c1(5,1) = 0.46;
par.c1(6,1) = 0.89;
par.c1(7,1) = 0.49;
par.c1(8,1) = 0.75;
par.c1(9,1) = 0.55;
par.c1(10,1) = 0.69;
par.c1(11,1) = 0.40;
par.c1(12,1) = 1;
par.c1(13,1) = 0.53;
par.c1(14,1) = 0.42;
par.c1(15,1) = 0.43;
par.c1(16,1) = 0.64;
par.c1(17,1) = 0.58;
par.c1(18,1) = 0.53;
par.c1(19,1) = 0.39;
par.c1(20,1) = 0.42;
par.c1(21,1) = 0.44;
par.c1(22,1) = 0.45;
par.c1(23,1) = 0.60;
par.c1(24,1) = 0.40;
par.c1(25,1) = 0.47;
par.c1(26,1) = 0.56;
par.c1(27,1) = 0.53;
par.c1(28,1) = 0.41;
par.c1(29,1) = 0.64;
par.c1(30,1) = 0.49;
par.c1(31,1) = 0.60;
par.c1(:,1) =par.c1(:,1) + 0.36;
%%
for testcluster = 1:model.nmodels
    par.testcluster = testcluster;
    for c1 = 0.2:0.2:1.4
        par.c1(testcluster, 2) = c1;
        for delta = 0.06
            par.delta = delta;
            for eta = 1
                par.eta = eta;
                % record all the results in each iteration
                GPSNR = [];
                GSSIM = [];
                for i = 1:im_num
                    par.image = i;
                    par.I = single( imread(fullfile(Original_image_dir, im_dir(i).name)) )/255;
                    S = regexp(im_dir(i).name, '\.', 'split');
                    randn('seed',0);
                    par.nim =   par.I + nSig/255*randn(size(par.I));
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
                mLPSNR=mean(par.LPSNR);
                mLSSIM=mean(par.LSSIM);
                mGPSNR=mean(par.GPSNR);
                mGSSIM=mean(par.GSSIM);
                fprintf('The average PSNR = %2.4f, SSIM = %2.4f. \n', mGPSNR,mGSSIM);
                name = sprintf('nSig%d_2_testcluster%d_delta%2.2f_eta%2.2f_c1%2.2f.mat',nSig,testcluster,delta,eta,c1);
                save(name,'nSig','LPSNR','LSSIM','mLPSNR','mLSSIM','GPSNR','GSSIM','mGPSNR','mGSSIM');
            end
        end
    end
end

