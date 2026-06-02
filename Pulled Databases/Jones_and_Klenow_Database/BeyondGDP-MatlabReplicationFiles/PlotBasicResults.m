% PlotBasicResults   8/25/14
%   Makes the key graphs of the macro results
%   Call after running RawlsLevels


figure(1); figsetup;
%plotlog(log(y),lambda,codes,'1/64 1/32 1/16 1/8 1/4 1/2 1',10);
%plotlog(log(y),lambda,namesSTR,'1/1024 1/256 1/64 1/16 1/4 1',10,[],.02,.01);
%plotlog(log(y),lambda,namesSTR,'1/256 1/64 1/16 1/4 1',10,[],.6,.2,namethese);
plotlog(log(y),lambda,namesSTR,'1/256 1/64 1/16 1/4 1',10,[],.8,.3,namethese);
set(gca,'XTick',log([1/128 1/64 1/32 1/16 1/8 1/4 1/2 1]));
set(gca,'XTickLabel',strmat('1/128#1/64 #1/32 #1/16 # 1/8 # 1/4 # 1/2 #  1  ','#'));
ax=axis; ax(1)=-5; axis(ax);
hold on;
gg=[log(1/128) log(1)];
plot(gg,gg,'b-','LineWidth',1);
chadfig('GDP per person (US=1)','Welfare, \lambda',1,0);
makefigwide;
print Rawls15.eps

figure(2); figsetup;
%plotname(log(y),lambda./y,codes,10);
%plotnamesym(log(y),lambda./y,namesSTR,10,[],0.035,0.0);
plotnamesym2(log(y),lambda./y,namesSTR,10,[],.6,.08,namethese);  %,[],0.035,0.0);
set(gca,'XTick',log([1/64 1/32 1/16 1/8 1/4 1/2 1]));
set(gca,'XTickLabel',strmat('1/64 1/32 1/16 1/8 1/4 1/2 1'));
%ax=axis; ax(1)=-4.5; ax(3)=0.3; ax(4)=1.8; axis(ax);
%hold on;
%plot(gg,gg,'b--','LineWidth',1.5);
%chadfig('GDP per person (US=1)','Lambda / GDP per person',1,0);
%chadfig('GDP per person (US=1)','Welfare \div GDP per person',1,0);
chadfig('GDP per person (US=1)','The ratio of Welfare to Income',1,0);
makefigwide;
print Rawls15B.eps

figure(3); figsetup;
%plotname(log(y),lambda./y,codes,10);
%plotnamesym(log(y),ell,namesSTR,10,[],0,0);
plotnamesym2(log(y(smpl)),ell(smpl),namesSTR(smpl,:),10,[],.6,0.01,namethese);
set(gca,'XTick',log([1/64 1/32 1/16 1/8 1/4 1/2 1]));
set(gca,'XTickLabel',strmat('1/64 1/32 1/16 1/8 1/4 1/2 1'));
%ax=axis; ax(1)=-4.5; axis(ax);
chadfig('GDP per person (US=1)','Leisure',1,0);
makefigwide;
print Rawls15C.eps
