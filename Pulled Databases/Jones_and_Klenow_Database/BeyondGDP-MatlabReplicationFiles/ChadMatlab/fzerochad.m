function x=fzerochad(f,x0,factor,NumTries,Verbose);

% Wrapper around fzero: x0=[xlow xhi].  Repeatedly update
%  by factor until find a sign change:  [xlow/factor(1) xhi*factor(2)].
%  Allows factor=[2 1.1] to update by different amounts in each direction.
%
%  f is the function to call.  We're looking for x s.t. f(x)=0

if exist('factor')~=1; factor=2; end;
if exist('NumTries')~=1; NumTries=5; end;
if exist('Verbose')~=1; Verbose=0; end;
if length(factor)==1; factor=[factor factor]; end;
x00=x0;

sign1=sign(f(x00(1)));
sign2=sign(f(x00(2)));
i=1;
while sign1==sign2 & i<NumTries;
  x00(1)=x00(1)/factor(1);
  x00(2)=x00(2)*factor(2);
  sign1=sign(f(x00(1)));
  sign2=sign(f(x00(2)));
  if Verbose;
      fprintf('  low=%10.5f  f(low)=%10.5f  | hi=%10.5f  f(hi)=%10.5f\n',[x00(1) f(x00(1)) x00(2) f(x00(2))]);
  end;
  i=i+1;
end;
if sign1==sign2; disp 'No sign change found in fzerochad. Stopping...'; keyboard; 
%if sign1==sign2; disp 'No sign change found in fzerochad. Assigning a NaN...';
  x=NaN;
else; 
  x=fzero(f,x00);
end;

