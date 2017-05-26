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
[nDCnlY, ~, ~, Par] = CalNonLocal( Par.nim, Par);
for ite = 1 : par.IteNum
    % iterative regularization
    im_out = im_out + Par.delta*(Par.nim - im_out);
    %     Y = Image2PatchNew( im_out, Par );
    
    % search non-local patch groups
    [nDCnlX,blk_arr,DC,Par] = CalNonLocal( im_out, Par);
    SigmaCol = Par.lambda2 * sqrt(abs(repmat(Par.nSig^2, 1, size(nDCnlX,2)) - mean((nDCnlY - nDCnlX).^2))); %Estimated Local Noise Level
    if ite == 1
        SigmaCol = Par.nSig * ones(size(SigmaCol));
    end
    % Gaussian dictionary selection by MAP
    if mod(ite-1,2) == 0
        PYZ = zeros(model.nmodels,size(DC,2));
        sigma2I = mean(SigmaCol.^2)*eye(Par.ps2);
        for i = 1:model.nmodels
            sigma = model.covs(:,:,i) + sigma2I;
            [R,~] = chol(sigma);
            Q = R'\nDCnlX;
            TempPYZ = - sum(log(diag(R))) - dot(Q,Q,1)/2;
            TempPYZ = reshape(TempPYZ,[Par.nlsp size(DC,2)]);
            PYZ(i,:) = sum(TempPYZ);
        end
        % find the most likely component for each patch group
        [~,dicidx] = max(PYZ);
        dicidx = dicidx';
        [idx,  s_idx] = sort(dicidx);
        idx2 = idx(1:end-1) - idx(2:end);
        seq = find(idx2);
        seg = [0; seq; length(dicidx)];
    end
    % Weighted Sparse Coding
    X_hat = zeros(Par.ps2,Par.maxrc,'single');
    W = zeros(Par.ps2,Par.maxrc,'single');
    for   j = 1:length(seg)-1
        idx =   s_idx(seg(j)+1:seg(j+1));
        cls =   dicidx(idx(1));
        D   =   Par.D(:,:, cls);
        S    = Par.S(:,cls);
        lambdaM = bsxfun( @rdivide, Par.c1*SigmaCol(index).^2, sqrt(S) + eps );
        for i = 1:size(idx,1)
            Y = nDCnlX(:,(idx(i)-1)*Par.nlsp+1:idx(i)*Par.nlsp);
            b = D'*Y;
            % soft threshold
%             alpha = solve_Lp ( b, lambdaM/2, Par.p );
            alpha = sign(b).*max(abs(b)-lambdaM/2,0);
            % add DC components and aggregation
            X_hat(:,blk_arr(:,idx(i))) = X_hat(:,blk_arr(:,idx(i)))+bsxfun(@plus,D*alpha, DC(:,idx(i)));
            W(:,blk_arr(:,idx(i))) = W(:,blk_arr(:,idx(i)))+ones(Par.ps2,Par.nlsp);
        end
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
            im_wei(r-1+i,c-1+j)  =  im_wei(r-1+i,c-1+j) + reshape( W(k,:)', [Par.maxr Par.maxc]);
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