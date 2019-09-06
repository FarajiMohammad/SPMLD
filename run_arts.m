function [obj_old,tstv2,P,lambda,gamma,in_result, out_result] = run_arts(dat0)

lambda0=0.0001;
gamma0=1;
% lambda=0.013;
% gamma=0.013;

param = importdata('arts_param.mat');
data = importdata(dat0);
% param = importdata('corel_param.mat');
% data = importdata('dt/Corel5k_sp.mat');

param.tooloptions.maxiter = 30;
param.tooloptions.gradnorm = 1e-3;
param.tooloptions.stopfun = @mystopfun;

 out_result = [];
 in_result = [];

    for j=3:4:8
        s = RandStream.create('mt19937ar','seed',1);
        RandStream.setGlobalStream(s);
       
        for kk = 1:1
            Xtrn = data.train{kk,1};
            Ytrn = data.train{kk,2};
            Xtst = data.test{kk,1};
            Ytst = data.test{kk,2};
            [J] = genObv( Ytrn, 0.1*j);
            tic;
            lambda=lambda0;
            gamma=gamma0;
            [obj_old,P,lambda,gamma,V,U,W,SP,Beta] = MLCTrain(J,Ytrn, Xtrn, Ytst,Xtst,param,lambda,gamma);
            tm = toc;
            zz = mean(Ytst);
            Ytst(:,zz==-1) = [];
            Xtst(:,zz==-1) = [];
            tstv = (U*W'*Xtst);
            ret =  evalt(tstv,Ytst, (max(tstv(:))-min(tstv(:)))/2);
            ret.time = tm;
            out_result = [out_result;ret];
            zz = mean(Ytrn);
            Ytrn(:,zz==-1) = [];
            Xtrn(:,zz==-1) = [];
            tstv2 = U*W'*Xtrn;
            ret =  evalt(tstv2,Ytrn, (max(tstv2(:))-min(tstv2(:)))/2);
            in_result = [in_result;ret];
        end
    end
end

function stopnow = mystopfun(problem, x, info, last)
    if last < 5 
        stopnow = 0;
        return;
    end
    flag = 1;
    for i = 1:3
        flag = flag & abs(info(last-i).cost-info(last-i-1).cost) < 1e-5;
    end
    stopnow = flag;
end