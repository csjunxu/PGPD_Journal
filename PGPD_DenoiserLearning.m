%------------------------------------------------------------------------------------------------
% PGPD_Denoising - Denoising by Weighted Sparse Coding
%                                with Learned Patch Group Prior.
% CalNonLocal - Calculate the non-local similar patches (Noisy Patch Groups)
% Author:  Jun Xu, csjunxu@comp.polyu.edu.hk
%              The Hong Kong Polytechnic University
%------------------------------------------------------------------------------------------------
function  [im_out,par] = PGPD_DenoiserLearning(par,model)
im_out = par.nim;
im_gt = par.I;
par.nSig0 = par.nSig;
[h,  w] = size(im_out);
par.maxr = h-par.ps+1;
par.maxc = w-par.ps+1;
par.maxrc = par.maxr * par.maxc;
par.h = h;
par.w = w;
r = 1:par.step:par.maxr;
par.r = [r r(end)+1:par.maxr];
c = 1:par.step:par.maxc;
par.c = [c c(end)+1:par.maxc];
par.lenr = length(par.r);
par.lenc = length(par.c);
par.lenrc = par.lenr*par.lenc;
par.ps2 = par.ps^2;
for ite = 1 : 2%par.IteNum
    % iterative regularization
    im_out = im_out + par.delta*(par.nim - im_out);
    % estimation of noise variance
    if ite == 1
        par.nSig = par.nSig0;
    else
        dif = mean( mean( (par.nim - im_out).^2 ) ) ;
        par.nSig = sqrt( abs( par.nSig0^2 - dif ) )*par.eta;
    end
    % search non-local patch groups
    [nDCnlY,nlX,blk_arr,DCY,par] = CalNonLocal( im_out, im_gt, par);
    % Gaussian dictionary selection by MAP
    if mod(ite-1,2) == 0
        nPG = size(nDCnlY,2)/par.nlsp; % number of PGs
        PYZ = zeros(model.nmodels, nPG);
        sigma2I = par.nSig^2*eye(par.ps2);
        for i = 1:model.nmodels
            sigma = model.covs(:,:,i) + sigma2I;
            [R,~] = chol(sigma);
            Q = R'\nDCnlY;
            TempPYZ = - sum(log(diag(R))) - dot(Q,Q,1)/2;
            TempPYZ = reshape(TempPYZ,[par.nlsp nPG]);
            PYZ(i,:) = sum(TempPYZ);
        end
        % find the most likely component for each patch group
        [~,cls_idx] = max(PYZ);
        cls_idx=repmat(cls_idx, [par.nlsp 1]);
        cls_idx = cls_idx(:);
        [idx,  s_idx] = sort(cls_idx);
        idx2 = idx(1:end-1) - idx(2:end);
        seq = find(idx2);
        seg = [0; seq; length(cls_idx)];
    end
    % Weighted Sparse Coding
    X_hat = zeros(par.ps2,par.maxrc, 'double');
    W = zeros(par.ps2,par.maxrc, 'double');
    for   j = 1:length(seg)-1
        idx =   s_idx(seg(j)+1:seg(j+1));
        cls =   cls_idx(idx(1));
        D   =   par.D(:,:, cls);
        S    = par.S(:,cls);
        lambdaM = repmat(par.c1(cls,ite)*par.nSig^2./ (sqrt(S)+eps ),[1 size(idx,1)]);
        Y = nDCnlY(:,idx);
        nlY = Y+DCY(:,idx);
        X = nlX(:,idx);
        if j <= par.testcluster && cls<= par.testcluster && ite == 2
            fprintf('Cluster %d:\n', cls);
        end
        b = D'*Y;
        % soft threshold
        alpha = sign(b).*max(abs(b)-lambdaM,0);
        % add DC components and aggregation
        Xr = bsxfun(@plus,D*alpha, DCY(:,idx));
        X_hat(:,blk_arr(idx)) = X_hat(:,blk_arr(idx)) + Xr;
        W(:,blk_arr(idx)) = W(:,blk_arr(idx)) + ones(par.ps2, size(idx,1));
    end
    % Reconstruction
    im_out = zeros(h,w,'double');
    im_wei = zeros(h,w,'double');
    r = 1:par.maxr;
    c = 1:par.maxc;
    k = 0;
    for i = 1:par.ps
        for j = 1:par.ps
            k = k+1;
            im_out(r-1+i,c-1+j)  =  im_out(r-1+i,c-1+j) + reshape( X_hat(k,:)', [par.maxr par.maxc]);
            im_wei(r-1+i,c-1+j)  =  im_wei(r-1+i,c-1+j) + reshape( W(k,:)', [par.maxr par.maxc]);
        end
    end
    im_out  =  im_out./im_wei;
    % calculate the PSNR and SSIM
    GPSNR = csnr( im_out*255, par.I*255, 0, 0 );
    GSSIM = cal_ssim( im_out*255, par.I*255, 0, 0 );
    fprintf('The Iter %d value of PSNR = %2.4f, SSIM = %2.4f\n',ite, GPSNR,GSSIM);
    par.GPSNR(ite,par.image) = GPSNR;
    par.GSSIM(ite,par.image) = GSSIM;
end
im_out(im_out > 1) = 1;
im_out(im_out < 0) = 0;
return;