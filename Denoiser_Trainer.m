clear;
Original_image_dir  =    '../20images/';
fpath = fullfile(Original_image_dir, '*.png');
im_dir  = dir(fpath);
im_num = length(im_dir);

%%
nSig = 50;
% [par, model]  =  Parameters_Setting( nSig );
load './model/PG_GMM_8x8_win15_nlsp10_delta0.002_cls33.mat';
par.nSig = nSig/255;
par.step = 3;       % the step of two neighbor patches
par.IteNum = 4;  % the iteration number
par.ps = ps;        % patch size
par.nlsp = nlsp;  % number of non-local patches
par.Win = win;   % size of window around the patch
% dictionary and regularization parameter
for i = 1:size(GMM_D,2)
    par.D(:,:,i) = reshape(single(GMM_D(:, i)), size(GMM_S,1), size(GMM_S,1));
end
par.S = single(GMM_S);
%%
for delta = 0.06
    par.delta = delta;
    for c1 = 0.25:0.05:0.5
        par.c1 = c1;
        for eta = 1
            par.eta=eta;
            % record all the results in each iteration
%             PSNR = [];
%             SSIM = [];
            for i = 1:im_num
                par.image = i;
                par.I = single( imread(fullfile(Original_image_dir, im_dir(i).name)) )/255;
                %         S = regexp(im_dir(i).name, '\.', 'split');
                randn('seed',0);
                par.nim =   par.I + par.nSig*randn(size(par.I));
                fprintf('%s :\n',im_dir(i).name);
                fprintf('The initial value of PSNR = %2.4f, SSIM = %2.4f \n', csnr( par.nim*255, par.I*255, 0, 0 ),cal_ssim( par.nim*255, par.I*255, 0, 0 ));
                %%
                [im_out,par]  =  PGPD_DenoiserLearning(par,model);
                im_out(im_out>1)=1;
                im_out(im_out<0)=0;
                %                 % calculate the PSNR
                %                 PSNR = [PSNR  csnr( im_out*255, par.I*255, 0, 0 )];
                %                 SSIM =  [SSIM cal_ssim( im_out*255, par.I*255, 0, 0 )];
                %                 imname = sprintf('PGPD_nSig%d_%s',nSig,im_dir(i).name);
                %                 imwrite(im_out,imname);
                fprintf('%s : PSNR = %2.4f, SSIM = %2.4f \n',im_dir(i).name, csnr( im_out*255, par.I*255, 0, 0 ), cal_ssim( im_out*255, par.I*255, 0, 0 ) );
            end
            fprintf('Cluster %d:\n', par.cluster);
            PSNR = par.PSNR(par.cluster,:);
            SSIM = par.SSIM(par.cluster,:);
            mPSNR=mean(PSNR);
            mSSIM=mean(SSIM);
            fprintf('The average PSNR = %2.4f, SSIM = %2.4f. \n', mPSNR,mSSIM);
            name = sprintf('nSig%d_Cluster%d_delta%2.2f_c%2.2f_eta%2.2f.mat',nSig,par.cluster,delta,c1,eta);
            save(name,'nSig','PSNR','SSIM','mPSNR','mSSIM');
        end
    end
end
