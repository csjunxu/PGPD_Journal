clear;
Original_image_dir  =    './20images/';
fpath = fullfile(Original_image_dir, '*.png');
im_dir  = dir(fpath);
im_num = length(im_dir);
nSig = 50;
[par, model]  =  Parameters_setting( nSig );
for c1 = 0.15
    par.c1 = c1*2*sqrt(2);
    for delta = 0.06
        par.delta = delta;
        for a = [0.25]
            par.a = a;
            for b = 0.62:-0.01:0.6
                par.b = b;
                for ec =  11
                    par.ec = ec;
                    for eta0 = [0.95 0.96 0.94]
                        par.eta0 = eta0;
                        for eta = [0.91 0.92 0.93 0.94]
                            par.eta=eta;
                            % record all the results in each iteration
                            PSNR = [];
                            SSIM = [];
                            T512 = [];
                            T256 = [];
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
                            mT512 = mean(T512);
                            sT512 = std(T512);
                            mT256 = mean(T256);
                            sT256 = std(T256);
                            fprintf('The average PSNR = %2.4f, SSIM = %2.4f. \n', mPSNR,mSSIM);
                            name = sprintf('PGPD_nSig%d_a%2.2f_b%2.2f_ec%2.2f_c%2.2f_delta%2.2f_eta0%2.3f_eta%2.2f.mat',nSig,a,b,ec,c1,delta,eta0,eta);
                            save(name,'nSig','PSNR','SSIM','mPSNR','mSSIM','mT512','sT512','mT256','sT256');
                        end
                    end
                end
            end
        end
    end
end