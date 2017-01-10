function       [nDCnlY,blk_arr,DC,par] = CalNonLocal( nim, cim, par)
% record the non-local patch set and the index of each patch in
% of seed patches in image
nim = single(nim);
Y   = zeros(par.ps2, par.maxrc, 'double');
X   = zeros(par.ps2, par.maxrc, 'double');
k   = 0;
for i = 1:par.ps
    for j = 1:par.ps
        k = k+1;
        blk = nim(i:end-par.ps+i,j:end-par.ps+j);
        Y(k,:) = blk(:)';
        cblk = cim(i:end-par.ps+i,j:end-par.ps+j);
        X(k,:) = cblk(:)';
    end
end
% index of each patch in image
Index    =   (1:par.maxrc);
Index    =   reshape(Index,par.maxr,par.maxc);
% record the indexs of patches similar to the seed patch
blk_arr   =  zeros(1, par.lenrc*par.nlsp ,'double');
% Patch Group Means
DC = zeros(par.ps2,par.lenrc*par.nlsp,'double');
% non-local patch groups
nDCnlY = zeros(par.ps2,par.lenrc*par.nlsp,'double');
nlX = zeros(par.ps2,par.lenrc*par.nlsp,'double');
for  i  =  1 :par.lenr
    for  j  =  1 : par.lenc
        row = par.r(i);
        col = par.c(j);
        off = (col-1)*par.maxr + row;
        off1 = (j-1)*par.lenr + i;
        % the range indexes of the window for searching the similar patches
        rmin = max( row - par.Win, 1 );
        rmax = min( row + par.Win, par.maxr );
        cmin = max( col - par.Win, 1 );
        cmax = min( col + par.Win, par.maxc );
        idx     =   Index(rmin:rmax, cmin:cmax);
        idx     =   idx(:);
        neighbor = Y(:,idx); % the patches around the seed in X
        seed  = Y(:,off);
        dis = sum(bsxfun(@minus,neighbor, seed).^2,1);
        [~,ind] = sort(dis);
        indc = idx( ind( 1:par.nlsp ) );
        indc(indc==off) = indc(1); % added on 08/01/2017
        indc(1) = off; % to make sure the first one of indc equals to off
        blk_arr(:,(off1-1)*par.nlsp+1:off1*par.nlsp)  =  indc;
        temp = Y( : , indc );
        DC(:,(off1-1)*par.nlsp+1:off1*par.nlsp) = repmat(mean(temp,2),[1 par.nlsp ]);
        nDCnlY(:,(off1-1)*par.nlsp+1:off1*par.nlsp) = bsxfun(@minus,temp, DC(:,(off1-1)*par.nlsp+1:off1*par.nlsp));
        nlX(:,(off1-1)*par.nlsp+1:off1*par.nlsp) = X( : , indc );
    end
end
% do not do the following, otherwise the patch groups will be clustered
% into the same (only one) group:
% nDCnlY(:,(off1-1)*par.nlsp+1:off1*par.nlsp) = temp;
% nDCnlY = nDCnlY - DC;