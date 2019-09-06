function [obj_old,P,lambda,gamma,V,U,W,MgPool,Beta,time,T,perf] = MLCTrain(J,Y, X, Ytst,Xtst,param,lambda,gamma)
  [d,n] = size(X);
  [l,~] = size(Y);
  k = param.k;
  k2 = param.k2;
  
  V = rand(k,n);
  W = zeros(d,k);
  U = rand(l,k);
  P=ones(k,n);
  
  perf = 0;

      
  o = sum(J(:));
  
  perf = [];
  param.lambda = param.lambda*o/(k*n);
  param.lambda1 = param.lambda1*o/((n/param.g)^2);
  param.lambda2 = param.lambda2*o/(n^2);
  param.lambda3 = param.lambda3*o/(n*k);
  param.lambda4 = param.lambda4*o/(l*k);
  param.lambda5 = param.lambda5*o/(d*k);
    
%    obj = 0.5*norm(J.*(Y-U*V),'fro')^2 + 0.5*param.lambda*norm(V-W'*X,'fro')^2;
%         zz = mean(Ytst);
%       Ytst(:,zz==-1) = [];
%       Xtst(:,zz==-1) = [];
%       tstv = (U*W'*Xtst);
%       perf_tmp =  evalt(tstv,Ytst, (max(tstv(:))-min(tstv(:)))/2);
%       perf_tmp.obj = obj;
%       perf = [perf;perf_tmp];
  tic;
  %[T, ~] = kmeans(X',param.g,'emptyaction','drop','MaxIter',50, 'Start','sample');
  [T, ~] = kmeans(X',param.g,'emptyaction','drop');
  cluster_time = toc;
  
  tic;
  [betav, XGXGPool, XX, param,PGr ] = InitGroup( P,Y, X,T, param );
  Beta = betav;
  
  g = param.g;
  MgPool = cell(g,1);
  LgPool = cell(g,1);
  for i = 1:g
      LgPool{i} = rand(l,k2);
  end
%   param.maxIter = 1;
%   param.tooloptions.maxiter = 10;
%   param.tooloptions.gradnorm = 1e-3;
  param.maxIter = 15;
  param.tooloptions.maxiter = 60;
  param.tooloptions.gradnorm = 1e-5;
  [ U,V,W ] = InitUVW(P,J,Y,U,V,W,X,XX,param);
  
   obj_old = [];
   last = 0;
  WXXW = W'*XX*W;
  UWXXWU = U*WXXW*U';
  WXGXGWPool = cell(g,1);
  UWXGXGWUPool = cell(g,1);
  for i = 1:g
      WXGXGWPool{i} = W'*XGXGPool{i,1}*W;
      UWXGXGWUPool{i} = U*WXGXGWPool{i}*U';
  end
  init_time = toc;
  
  tic;
  for i=1:param.maxIter 
      disp(i);
      for gr=1:g
          UWXGXGWU = UWXGXGWUPool{gr};
          A=U*(P.*(W'*X));
          Ag=U*(PGr{gr}.*(W'*XGXGPool{gr,2}));
          [Lg] = UpdateS(Ag,A,W,LgPool{gr},betav(gr),UWXXWU,UWXGXGWU,param);
          LgPool{gr} = Lg;
          MgPool{gr} = Lg*Lg';
      end  
      [ V ] = UpdateV(P,V, J,Y,U,W,X,param );
      [ U ] = UpdateU(P,U, J, Y, V, betav,MgPool, W, X, XGXGPool, WXXW,WXGXGWPool, param, PGr );        
      [ W, WXXW,WXGXGWPool ] = UpdateW(P, W, U, V, X, betav, XX,PGr, XGXGPool, MgPool, param );
       UWXXWU = U*WXXW*U';
       for gr=1:g
           UWXGXGWUPool{gr} = U*WXGXGWPool{gr}*U';
       end 
       
%       [ V ] = UpdateV( V, Y, U, W, X, param);
%       [U,USU] = UpdateU( U, Y, V, S, WXXW, USU, param );
%       [ W, WXXW ] = UpdateW(W, V, X, XX, WXXW, USU, param);
%       UWXXWU = U'*WXXW*U;
%       [ L,S,USU ] = UpdateS(L,U, UWXXWU);
%       obj = 0.5*norm(Y-U*V)^2 + 0.5*param.lambda1*trace(WXXW*USU) + 0.5*param.lambda2*norm(U)^2 + 0.5*param.lambda3*norm(W)^2;
      obj = 0.5*norm(J.*(Y-U*V),'fro')^2 + 0.5*param.lambda*norm(P.*(V-W'*X),'fro')^2;
      L=(V-W'*X).^2;
      %L=1-exp(-L);
      mi=min(min(L));
      ma=max(max(L));
      L=(L-mi)/(ma-mi);
      
      %P=updateP(L,lambda,gamma);
      P=updateP(L,lambda,gamma);
      sum(sum(P))
      sum(vecnorm(P'));
      mu1=1.3;
      mu2=0.6;
      lambda=lambda*mu1;
      gamma=gamma*mu2;
      PGr = PGroup(P,T);
%       zz = mean(Ytst);
%       Ytst(:,zz==-1) = [];
%       Xtst(:,zz==-1) = [];
%       tstv = (U*W'*Xtst);
%       perf_tmp =  evalt(tstv,Ytst, (max(tstv(:))-min(tstv(:)))/2);
%       perf_tmp.obj = obj;
%       perf = [perf;perf_tmp];
      disp(obj);
      last = last + 1;
      obj_old = [obj_old;obj];
      
      
      if last < 5
          continue;
      end
      stopnow = 1;
      for ii=1:3
         stopnow = stopnow & (abs(obj-obj_old(last-1-ii)) < 1e-6);
      end
      if stopnow
          break;
      end
  end

   alg_time = toc;
    time.fill=0;
  time.clust=cluster_time;
  time.init = init_time;
  time.run = alg_time;
end

