%------------------------------------------------------------------------------------------------
% PGPD_Denoising - Denoising by Weighted Sparse Coding
%                                with Learned Patch Group Prior.
% CalNonLocal - Calculate the non-local similar patches (Noisy Patch Groups)
% Author:  Jun Xu, csjunxu@comp.polyu.edu.hk
%              The Hong Kong Polytechnic University
%------------------------------------------------------------------------------------------------
function  [im_out,Par] = PGPD_Denoising(Par,model)
im_out = Par.nim;
Par.nSig0 = Par.nSig;
[h,  w, ch] =  size(im_out);
Par.maxr = h-Par.ps+1;
Par.maxc = w-Par.ps+1;
Par.maxrc = Par.maxr * Par.maxc;
Par.h = h;
Par.w = w;
Par.ch = ch;
Par = SearchNeighborIndex( Par );
% NY = Image2PatchNew( Par.nim, Par );
[nDCnlY, blk_arr, DC, Par] = CalNonLocal( Par.nim, Par);
for ite = 1 : Par.IteNum
    % iterative regularization
    im_out = im_out + Par.delta*(Par.nim - im_out);
    %     Y = Image2PatchNew( im_out, Par );
    if ite == 1
        nDCnlX = nDCnlY;
        SigmaCol = Par.nSig * ones(1, size(nDCnlX, 2));
    else
        % search non-local patch groups
        [nDCnlX,blk_arr,DC,Par] = CalNonLocal( im_out, Par);
        % estimate the noise stds of each patch
        SigmaCol = Par.eta * sqrt(abs(repmat(Par.nSig^2, 1, size(nDCnlX,2)) - mean((nDCnlY - nDCnlX).^2))); %Estimated Local Noise Level
    end
    % Gaussian dictionary selection by MAP
    if mod(ite-1, 2) == 0
        PYZ = zeros(model.nmodels,size(nDCnlX,2));
        sigma2I = mean(SigmaCol(1)^2)*eye(Par.ps2);
        for i = 1:model.nmodels
            sigma = model.covs(:,:,i) + sigma2I;
            [R,~] = chol(sigma);
            Q = R'\nDCnlX;
            PYZ(i,:) = - sum(log(diag(R))) - dot(Q,Q,1)/2;
        end
        % find the most likely component for each patch group
        [~,dicidx] = max(PYZ);
        dicidx = dicidx';
        [idx,  s_idx] = sort(dicidx);
        idx2 = idx(1:end-1) - idx(2:end);
        seq = find(idx2);
        seg = [0; seq; length(dicidx)];
    else
        %% add the code of gating network
    end
    % Weighted Sparse Coding
    X_hat = zeros(Par.ps2,Par.maxrc,'single');
    W_hat = zeros(Par.ps2,Par.maxrc,'single');
    for   j = 1:length(seg)-1
        idx =   s_idx(seg(j)+1:seg(j+1));
        cls =   dicidx(idx(1));
        D   =   Par.D(:,:, cls);
        sqrtS    = sqrt(Par.S(:,cls));
        Wst = bsxfun( @rdivide, Par.c1*SigmaCol(idx).^2, sqrtS + eps );
        Y = nDCnlX(:, idx);
        b = D'*Y;
        % soft threshold
        alpha = solve_Lp ( b, Wst/2, Par.p );
        %         alpha = sign(b).*max(abs(b)-Wst/2,0);
        Xhat = D*alpha;
        X_hat(:,blk_arr(1, idx)) = X_hat(:,blk_arr(idx))+bsxfun(@plus, Xhat, DC(:,idx));
        W_hat(:,blk_arr(idx)) = W_hat(:,blk_arr(idx))+ones(Par.ps2ch, length(idx));
        %                 W2 = 1 ./ (SigmaCol(index) + eps);
        %                 Y_hat(:, index) = Y_hat(:, index) + bsxfun(@times, nlYhat, W2);
        %         W_hat(:, index) = W_hat(:, index) + repmat(W2, [Par.ps2ch, 1]);
    end
    % Reconstruction
    im_out = zeros(h,w,'single');
    im_wei = zeros(h,w,'single');
    r = 1:Par.maxr;
    c = 1:Par.maxc;
    k = 0;
    for i = 1:Par.ps
        for j = 1:Par.ps
            k = k+1;
            im_out(r-1+i,c-1+j)  =  im_out(r-1+i,c-1+j) + reshape( X_hat(k,:)', [Par.maxr Par.maxc]);
            im_wei(r-1+i,c-1+j)  =  im_wei(r-1+i,c-1+j) + reshape( W_hat(k,:)', [Par.maxr Par.maxc]);
        end
    end
    im_out  =  im_out./im_wei;
    % calculate the PSNR and SSIM
    GPSNR =   csnr( im_out*255, Par.I*255, 0, 0 );
    GSSIM      =  cal_ssim( im_out*255, Par.I*255, 0, 0 );
    fprintf('Iter %d : PSNR = %2.4f, SSIM = %2.4f\n',ite, GPSNR,GSSIM);
    Par.GPSNR(ite,Par.image) = GPSNR;
    Par.GSSIM(ite,Par.image) = GSSIM;
end
im_out(im_out > 1) = 1;
im_out(im_out < 0) = 0;
return;

