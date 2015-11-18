%% Matrix Stochastic Gradient Descent for PCA
% from "Stochastic Optimization of PCA with Capped MSG", Arora et al

% very similar to incremental pca, but with better theoretical bounds
% for convergence, and it is guaranteed not to get "stuck". 

% update of the form P^(t) = P_{trace(P) = k, P<= I}(P^(t-1) + \eta_t*x*x^T)
% but stored in the form of an singular value decomposition of the 
% covariance (2nd moment) matrix as so:

function U = msg(X, k)

    X = X';               % to make things work. X is matrix of [0, 255]
    X = normc(X); %OH GOD
    iters = 1;            % how many times to loop over entire training set
    t = 0;                % iterate
    n = size(X, 2);       % number of examples
%     k = 200               % MUST conform to api: return a dxn matrix
    d = size(X, 1);       % dimensionality
    U = orth(rand(d, k)); % randomly init learned subspace, d by k
    S = diag(ones(k, 1)); %1000*rand(k,1)); % C^0 = USU^T random eigendecomposition, k by k
%     S = diag(sort(generateKsumM(1, k, k), 'descend')); %create k random eigenvalues who sum to k
    %see if the largest eigenvalue is on the same order as max(svds(X))

    
    if(size(X, 1) ~= 32256)           %obviously change
       size(X)
       error('IPCA: bad input');
    end
    h = waitbar(0,'Initializing waitbar...');
    for i = 1:iters
        fprintf('----iteration %d\n', i);
%         X(:,randperm(size(X,2)));         %good practice to shuffle:
        for t = 1:n; 
           x = X(:, t);
           
           x = abs(x/mean(x)); %attempt to fix: is this going to work?
           
           eta = 1/nthroot((i-1)*n + t, 2);
           x_hat = nthroot(eta, 2)*U'*x;
           x_perp = nthroot(eta, 2)*x - U*x_hat;
           
%            size(x_hat)
%            size(x_perp)
%            size(S)
           
           r = norm(x_perp) %this is too big because data not mean-centered!
           
           if (r > 0) 
               Q = [S + x_hat*x_hat', r*x_hat; r*x_hat', r^2]; %putting

               [V, S_prime] = eig(Q);
               U = [U, x_perp/r]*V;
               S = S_prime;
           else %(r == 0)
               Q = [S + x_hat*x_hat'/1000];
               [V, S_prime] = eig(Q);
               U = U*V;
               S = S_prime;
           end
           waitbar((n*(i-1) + t)/(iters*n),h)
           m = rank(U);
           %PROJECT: algorithm 2
            sigma = diag(S)
            sigma_u = unique(sigma);
            
            size(sigma_u)
            
            if (length(sigma_u) == 1) 
                kappa = length(sigma);
            else
                kappa = hist(sigma, sigma_u);
            end
            sigma = sigma_u;
            
           if (sum(kappa) ~= m) %maybe??
               sum(kappa)
               error('kappa not summing to d')
           end
           sigma = project(d, k, m, sigma, kappa);
           
           if (sum(sigma) ~= k)
               display('----------------');
               sum(sigma)
               sigma
               warning('sum of sigmas does not equal k, projection failed')
               error('sum of sigmas does not equal k, projection failed')

%                sigma = [sigma; ones(k - size(sigma, 1), 1)]
           end
           
           S = diag(sigma);
           indices = find(sigma == 0);
           U(:, indices) = [];
           ranku = rank(U)
           
           %also try:
           %uA = unique(A);
           %mult = nonzeros(accumarray(A(:),1,[],@sum,0,true))
           
             
        end
        
    end
    close(h);
    
end
function sigma = project(d, k, n, sigma, kappa)
    
    [sigma, I] = sort(sigma, 'descend')
    kappa = kappa(I); %also re-sort these
    
    fprintf('size of sigma in project: %d\n', length(sigma));
    if (length(sigma) <= 2)
        sigma
        error('sigma is only one in project()!');
    end
    
    i   = 1;
    j   = 1;
    s_i = 0;
    s_j = 0;
    c_i = 0;
    c_j = 0;
    S   = 0;
    
    while i <= n
        if (i < j)
           S = (k - (s_j - s_i) - (d - c_j))/(c_j - c_i)
           b = ((sigma(i) + S >= 0) && (sigma(j-1) + S <= 1)...
                 && ((i <= 1) || (sigma(i - 1) + S <= 0))...
                 && ((j >= n) || (sigma(j+1) >= 1)));
           if (b == true)
               S
               for i = 1:length(sigma)
                    sigma(i) = max(0, min(1, sigma(i) - S));
               end
               display('returned properly');
               return;
           end
        end
        if ( (j <= n) && (sigma(j) - sigma(i) <= 1))
            s_j = s_j + kappa(j)*sigma(j);
            c_j = c_j + kappa(j);
            j = j + 1;
        else
           s_i = s_i + kappa(i)*sigma(i);
           c_i = c_i + kappa(i);
           i = i + 1;
        end
            
    end
    error('projection did  NOT occur properly');
    
    

end

