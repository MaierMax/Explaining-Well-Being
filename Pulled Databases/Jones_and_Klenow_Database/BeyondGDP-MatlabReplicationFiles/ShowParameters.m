% ShowParameters.m 8/29/14
%
%  Display the main parameters of the Rawls setup


disp ' ';
disp '=====================';
disp 'KEY PARAMETER VALUES:'; 
disp '=====================';
fprintf('       Frisch LS Elas = %8.4f\n',FrischLSElasticity);
fprintf(' ValueLife2005Dollars = %8.4f\n',ValueofLife2005dollars);
fprintf('                 beta = %8.4f\n',beta);
fprintf('                    g = %8.4f\n',g);
fprintf('                 ubar = %8.4f\n',ubar);
fprintf('                theta = %8.4f\n',theta);
if exist('gamma')==1;
fprintf('                gamma = %8.4f\n',gamma);
fprintf('            clowerbar = %8.4f\n',clowerbar);
end;
if exist('StartAge')==1;
fprintf('             StartAge = %8.0f\n',StartAge);
end;    
if exist('KidsGetAdultLeisure')==1;
fprintf('  KidsGetAdultLeisure = %8.0f\n',KidsGetAdultLeisure);
end;    
if exist('HHSizeEquivScale')==1;
    if HHSizeEquivScale~=0;
        fprintf('     HHSizeEquivScale = %8.0f\n',HHSizeEquivScale);
    end;    
end;

disp ' ';
