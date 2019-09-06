function [ U,V,W ] = InitUVW(P,J,Y,U,V,W,X,XX,param)
     [l,k] = size(U);
     [d,k] = size(W);
     [k,n] = size(V);
     obj_old = [];
     last = 0;
     
     lambda = param.lambda;
     
     for i=1:param.maxIter
        U= upu(P,U,J,Y,V,param,l,k) ;
        V =upv(P,V,J,Y,U,W,X,param,k,n);  
        W = upw(P,W,J,V,X,param,k,d);
        
        obj = 0.5*norm(J.*(Y-U*V),'fro')^2 + 0.5*lambda*norm(P.*(V-W'*X),'fro')^2;
         disp(obj);
         last = last + 1;
         obj_old = [obj_old;obj];
      
      
          if last < 5
             continue;
          end 
          stopnow = 1;
          for ii=1:3
             stopnow = stopnow & (abs(obj-obj_old(last-1-ii)) < 1e-3);
          end
          if stopnow
             break;
          end
     end
%    [U, V, objGCD, timeGCD] = NMF_GCD(Y,k,param.maxIter*50,U,V,1);
   
%      for i=1:param.maxIter
%           W =upw(W,V,X,param,k,d);
%      end
end
function W =upw(P,W,J,V,X,param,k,d)
          manifold = euclideanfactory(d, k);
          problem.M = manifold;
          problem.cost = @(x) Wcost(P,x,J,V,X,param);
          problem.grad = @(x) Wgrad(P,x,J,V,X,param);
          %problem.finalproj = @(x) Wproj(x);
          options = param.tooloptions;
         %  [x xcost info] = trustregions(problem,W,options);
          [x xcost info] = steepestdescent(problem,W,options);
         %[x xcost info] = conjugategradient(problem,W,options);
         W = x; 
end
function V =upv(P,V,J,Y,U,W,X,param,k,n)
        manifold = euclideanfactory(n, k);
        %manifold = stiefelfactory(n,k);
        problem.M = manifold;
   
        %problem.finalproj = @(x) Vproj(x);
        problem.cost = @(x) Vcost(P,x,J,Y,U,W,X,param);
        problem.grad = @(x) Vgrad(P,x,J,Y,U,W,X,param);
    
       options = param.tooloptions;
      % [x xcost info] = trustregions(problem,V',options);
        [x xcost info] = steepestdescent(problem,V',options);
      % [x xcost info] = conjugategradient(problem,V',options);
       V = x';
end
function U= upu(P,U,J,Y,V,param,l,k) 
        manifold = euclideanfactory(l, k);
        problem.M = manifold;
 
        problem.cost = @(x) Ucost(P,x,J,Y,V,param);
        problem.grad = @(x) Ugrad(P,x,J,Y,V,param);
        %problem.finalproj = @(x) Uproj(x);
        options = param.tooloptions;     
        %  [x xcost info] = trustregions(problem,U,options);
        [x xcost info] = steepestdescent(problem,U,options);
%         [x xcost info] = conjugategradient(problem,U,options);
        U = x;
end        


function proj = Vproj(V)
   V(V<0) = 0;
   proj = V;
end

function cost = Vcost(P,V,J,Y,U,W,X,param)
     lambda = param.lambda;
     lambdav = param.lambda3;
     cost = 0.5*norm(J.*(U*V'-Y),'fro')^2 + 0.5*param.lambda3*norm(V,'fro')^2 ...
         + 0.5*param.lambda*norm(P.*(V'-W'*X),'fro')^2;
end

function grad = Vgrad(P,V,J,Y,U,W,X,param)
     
     lambda = param.lambda;
     lambdav = param.lambda3;
     grad = (U'*(J.*(U*V'-Y).*J))' + param.lambda* (P.*(V'-W'*X).*P)' + param.lambda3*V;
end

function proj = Uproj(U)
   U(U<0) = 0;
   proj = U;
end

function cost = Ucost(P,U,J,Y,V,param)
     
     lambdau = param.lambda4;
     cost = 0.5*norm(J.*(U*V-Y),'fro')^2 + 0.5*lambdau*norm(U,'fro')^2;
end

function grad = Ugrad(P,U,J,Y,V,param)
     
     lambdau = param.lambda4;
     grad = (J.*(U*V-Y).*J)*V' + lambdau*U;
end

function proj =Wproj(W)
   W(W<0) = 0;
   proj = W;
end

function cost = Wcost(P,W,J, V, X,param)
     
     lambda = param.lambda;
     lambdaw = param.lambda5;
          
     cost = 0.5*lambda*norm(P.*(W'*X-V),'fro')^2 + 0.5*lambdaw*sum(vecnorm(W'));
end

function grad = Wgrad(P,W,J,V,X,param)
     
     lambda = param.lambda;
     lambdaw = param.lambda5;
     D=diag(1./(2*vecnorm(W')+eps));
     grad = lambda*X*(P'.*(X'*W - V').*P') + lambdaw*D*W;
end

