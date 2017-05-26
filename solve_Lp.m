% ===========================================================
% min_y 0.5 (y-c)^2 + r * |y|^p
%  where y and c are vectors or matrices
function   y = solve_Lp ( c, r, p )
if p<0
    p=1;
end
if p<1
% Modified by Dr. Weisheng Dong
J     =  2;
tau   =  (2*r.*(1-p)).^(1/(2-p)) + p*r.*(2*(1-p)*r).^((p-1)/(2-p));
y     =  zeros( size(c) );
i0    =  find( abs(c)>tau );

if length(i0) >= 1
    % lambda  =   lambda(i0);
    c0    =   c(i0);
    t     =   abs(c0);
    for  j  =  1 : J
        t    =  abs(c0) - p*r.*(t).^(p-1);
    end
    y(i0)   =  sign(c0).*t;
end
else
    y = sign(c).*max(abs(c)-r/2,0);
end
    
end