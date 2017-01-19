clear;
Original_image_dir  =    'C:/Users/csjunxu/Desktop/Projects/4000images/';
fpath = fullfile(Original_image_dir, '*.png');
TD = regexp(Original_image_dir, '/', 'split');
%%
nSig = 50;
[par, model]  =  Parameters_Setting( nSig );
par.Original_image_dir = Original_image_dir;
par.fpath = fpath;
par.TD = TD{end-1};
%%
resultpath = dir([par.TD '/*.mat']);
resultlist={resultpath.name}';
%% set the step size of c
cstep = 0.05;

for IteNum = 1:1:4
    par.IteNum = IteNum;
    testcluster = 1;
    while testcluster <= model.nmodels
        resultname = sprintf('100_nSig%d_IteNum%d_cluster%d_', nSig, IteNum, testcluster);
        resultexist = regexp(resultlist, resultname);
        resultexist = ~cellfun('isempty', resultexist);
        if sum(resultexist)
            pos = find(resultexist==1);
            eval(['load ' par.TD '/' resultlist{pos(end)}]);
            if abs(mGPSNR(end) - mGPSNR(end - 1))< 1e-5
                testcluster = testcluster + 1;
                continue;
            else
                S = regexp(resultlist{pos(end)}, '_', 'split');
                c1 = str2double(S{end}(2:5));
                Denoiser_Trainer(model, par, nSig, IteNum, testcluster, c1, cstep, mGPSNR, mGSSIM);
            end
        else
            mGPSNR = 0;
            mGSSIM = 0;
            c1 = 0;
            Denoiser_Trainer(model, par, nSig, IteNum, testcluster, c1, cstep, mGPSNR, mGSSIM);
        end
        testcluster = testcluster + 1;
    end
end
