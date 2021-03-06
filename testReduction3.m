function [R Z y] = testReduction3(A,y,alpha,sigma)
%Perform LLL, then a variant of CH where alpha gives a tradeoff between LLL
%and CH
    [m n] = size(A);
    if(checkLLL(A) == 1)
        [Q R] = qr(A);
        y = Q'*y;
        Z = eye(n,n);
    else
        [R Z y] = reduction(A,y);
    end
    [~, ~, offDiagSum,~] = checkLLL(R);
    offDiagSumOrig = offDiagSum;
    k=n;
    
    yhat = y;
    zhat = zeros(n,1);
    noCH=n+1;
    while k>=1

        if k>n
            k = n;
        end
        
        if(k<noCH)
            
            %Find the column we should permute to the kth using the CH strategy
            if(k < n)
                yhat(1:k) = yhat(1:k) - R(1:k,k+1)*zhat(k+1);
            end
            ck = yhat(k)/R(k,k);
            zk = round(ck);
            zk = zk + sign(ck-zk);
            bestDist = abs(R(k,k)*(ck-zk));
            curDist = bestDist;
            p=k;
            R2=R;
            for i = 1:k-1
                Rp=R;
                yp=yhat;
                yTemp=y;
                [Rp,yp,yTemp] = permufull(Rp,yp,yTemp,i,k); %swap column k and i - return to upper tri
                ckp = yp(k)/Rp(k,k);
                zkp = round(ckp);
                zkp = zkp + sign(ckp-zkp);
                testDist = abs(Rp(k,k)*(ckp-zkp));
                if(testDist > bestDist)
                    bestDist = testDist;
                    p = i;
                    R2 = Rp;
                    y2=yTemp;
                    Z2 = Z;
                    Z2(:,[k,p])=Z(:,[p,k]); %record the column swap in Z
                    yhat2 = yp;
                    ck2 = ckp;
                end
            end
            %measure = offDiagSum2;
            measure = abs((2*sigma)./R2(k,k));
            if(p~=k && (offDiagSum == 0 || measure <= alpha) )
                j=k-1;
                while j>=2
                    if j>=k-1
                        j = k-1;
                    end
                    % Size reduction
                    [R2,Z2] = IGT(R2,Z2,j);
                    % Column swap
                    gamma = R2(j,j)^2 + R2(j-1,j)^2;
                    if gamma < R2(j-1,j-1)^2
                        [R2,Z2,yhat2,y2] = swap(R2,j-1,Z2,yhat2,y2);
                        j = j + 1;
                    else    
                        j = j - 1;
                    end 
                end
                R = R2;
                y = y2;
                Z = Z2;
                yhat = yhat2;
                ck = ck2;
                [~, ~, offDiagSum,~] = checkLLL(R2(1:k-1,1:k-1));
              
                %fprintf('Swapped: %i %i %f\n',k,i,measure);
            else
                if (p~=k)
                    %fprintf('Skipped swap: %i %i %f\n',k,i,measure);
                end
            end

            zhat(k) = round(ck);
        end
    
        k=k-1;
    end
end