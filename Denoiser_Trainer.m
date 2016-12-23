clear;
Original_image_dir  =    '../20images/';
fpath = fullfile(Original_image_dir, '*.png');
im_dir  = dir(fpath);
im_num = length(im_dir);
% load model according to noise levels
nSig = 50;
[par, model]  =  Parameters_Setting( nSig );

for c1 = 0.15
    par.c1 = c1;
    for delta = 0.06
        par.delta = delta;
        for eta = [0.91 0.92 0.93 0.94]
            par.eta=eta;
            % record all the results in each iteration
            PSNR = [];
            SSIM = [];
            for i = 1:im_num
                par.image = i;
                par.I = single( imread(fullfile(Original_image_dir, im_dir(i).name)) )/255;
                %         S = regexp(im_dir(i).name, '\.', 'split');
                randn('seed',0);
                par.nSig = nSig/255;
                par.nim =   par.I + par.nSig*randn(size(par.I));
                fprintf('%s :\n',im_dir(i).name);
                fprintf('The initial value of PSNR = %2.4f, SSIM = %2.4f \n', csnr( par.nim*255, par.I*255, 0, 0 ),cal_ssim( par.nim*255, par.I*255, 0, 0 ));
                
                [im_out,par]  =  PGPD_Denoiser(par,model);
                im_out(im_out>1)=1;
                im_out(im_out<0)=0;
                % calculate the PSNR
                PSNR = [PSNR  csnr( im_out*255, par.I*255, 0, 0 )];
                SSIM =  [SSIM cal_ssim( im_out*255, par.I*255, 0, 0 )];
                %                 imname = sprintf('PGPD_nSig%d_%s',nSig,im_dir(i).name);
                %                 imwrite(im_out,imname);
                fprintf('%s : PSNR = %2.4f, SSIM = %2.4f \n',im_dir(i).name, csnr( im_out*255, par.I*255, 0, 0 ), cal_ssim( im_out*255, par.I*255, 0, 0 ) );
            end
            mPSNR=mean(PSNR);
            mSSIM=mean(SSIM);
            fprintf('The average PSNR = %2.4f, SSIM = %2.4f. \n', mPSNR,mSSIM);
            name = sprintf('PGPD_nSig%d_c%2.2f_delta%2.2f_eta%2.2f.mat',nSig,c1,delta,eta);
            save(name,'nSig','PSNR','SSIM','mPSNR','mSSIM','mT512','sT512','mT256','sT256');
        end
    end
end
