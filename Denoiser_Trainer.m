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
%%
for c1 = 0.1:0.1:1
    par.c1(11,1) = c1;
    par.testcluster = 11;
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
                im_out(im_out>1)=1;
                im_out(im_out<0)=0;
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
            name = sprintf('nSig%d_Cluster%d_delta%2.2f_c%2.2f_eta%2.2f.mat',nSig,par.testcluster,delta,c1,eta);
            save(name,'nSig','LPSNR','LSSIM','mLPSNR','mLSSIM','GPSNR','GSSIM','mGPSNR','mGSSIM');
        end
    end
end
