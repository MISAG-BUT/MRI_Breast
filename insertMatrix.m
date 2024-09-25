function R = insertMatrix(B,b,varargin)

V = size(B,1);
V(2) = size(B,2);
V(3) = size(B,3);
v = size(b,1);
v(2) = size(b,2);
v(3) = size(b,3);

B = double(B);
b = double(b);

if nargin==2
    c = ceil(V./2);
    mode = 'replace';
    cut = true;
elseif nargin == 3
    if ischar(varargin{1})
        mode = varargin{1};
        c = ceil(V./2);
        cut = true;
    else
        c = varargin{1};
        mode = 'replace';
        cut = true;
    end
elseif nargin == 4
    c = varargin{1};
    mode = varargin{2};
    cut = true;
elseif nargin == 5
    c = varargin{1};
    mode = varargin{2};
    cut = str2num(varargin{3});    
end

if isempty(c)
    c = ceil(V./2);
end
c = double(c);

r = V;
R = B;

pb = c - floor(v/2);

posunPRE = round(abs(pb .* double(pb<1)) + double(pb<1));

dif1 = (r - (pb+v-1));
posunPOST = round(abs(dif1 .* double(dif1<0)));


R = padarray(R,[posunPRE],0,'pre');
R = padarray(R,[posunPOST],0,'post');

pb = pb + posunPRE;
r = size(R,1);
r(2) = size(R,2);
r(3) = size(R,3);

switch mode
    case 'replace'
        R(pb(1):pb(1)+v(1)-1,pb(2):pb(2)+v(2)-1,pb(3):pb(3)+v(3)-1) = b;

    case 'add'
        R(pb(1):pb(1)+v(1)-1,pb(2):pb(2)+v(2)-1,pb(3):pb(3)+v(3)-1) = R(pb(1):pb(1)+v(1)-1,pb(2):pb(2)+v(2)-1,pb(3):pb(3)+v(3)-1) + b;
    
    case 'max'
        R(pb(1):pb(1)+v(1)-1,pb(2):pb(2)+v(2)-1,pb(3):pb(3)+v(3)-1) = max( R(pb(1):pb(1)+v(1)-1,pb(2):pb(2)+v(2)-1,pb(3):pb(3)+v(3)-1), b);

    case 'and'
        R(pb(1):pb(1)+v(1)-1,pb(2):pb(2)+v(2)-1,pb(3):pb(3)+v(3)-1) = R(pb(1):pb(1)+v(1)-1,pb(2):pb(2)+v(2)-1,pb(3):pb(3)+v(3)-1) .* b;
        
    case 'masked_replace'
        R1 =  R(pb(1):pb(1)+v(1)-1,pb(2):pb(2)+v(2)-1,pb(3):pb(3)+v(3)-1);
        ind = b>0;
        R1(ind) = b(ind);
        R(pb(1):pb(1)+v(1)-1,pb(2):pb(2)+v(2)-1,pb(3):pb(3)+v(3)-1) = R1;
end

if cut
R = R(posunPRE(1)+1:r(1)-posunPOST(1),...
              posunPRE(2)+1:r(2)-posunPOST(2),...
              posunPRE(3)+1:r(3)-posunPOST(3)  );
end

