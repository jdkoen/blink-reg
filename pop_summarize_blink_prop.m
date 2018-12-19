% pop_summarize_blink_prop() -  This function plots summary data for the
%                               estimated blink propogation. This requires 
%                               the EEG.fnim_blink field to be present in
%                               the EEG structure.
%
% Usage:
%   >>  [EEG, com] = pop_summarize_blink_prop( EEG )
%
% Inputs:
%   EEG         - input EEG dataset (if using GUI, this is current EEG set)
%    
% Outputs:
%   EEG         - output dataset (unchanged from input
%
% See also:
%    POP_EST_BLINK_PROP, EST_BLINK_PROP

% Copyright (C) 2015  Joshua D. Koen
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

function [EEG, com] =  pop_summarize_blink_prop( EEG )

com = '';

%% Return help if only EEG or no inputs are given
if nargin < 1
	help pop_summarize_blink_prop;
	return; 
end;

%% Check EEG structure for appropriate field
if ~isfield(EEG,'fnim_blink')
    error('fnim_blink field has not been created. Manually mark blinks first.')
end

%% Plot Blink ERP in a topo plot
f1 = figure('Position',[50 100 1000 800],'Color','w');
subplot(2,4,[1:3 5:7])
ymin = min(EEG.fnim_blink.blinkERP(:));
ymax = max(EEG.fnim_blink.blinkERP(:));
plottopo(EEG.fnim_blink.blinkERP(:,:,1),'chanlocs',EEG.chanlocs,'ydir',1, ...
    'vert',EEG.fnim_blink.options.baseWin,'ylim',[ymin ymax])
firstTable = ceil(1:EEG.nbchan/2);
secondTable = firstTable(end)+1:EEG.nbchan;
chanLabels = {EEG.chanlocs.labels};
uitable('Parent',f1,'Data',EEG.fnim_blink.propogation_weights(firstTable),'ColumnName','b', ...
    'RowName',chanLabels(firstTable),'Position',[750 170 110 600],'ColumnWidth',{50});
uitable('Parent',f1,'Data',EEG.fnim_blink.propogation_weights(secondTable),'ColumnName','b', ...
    'RowName',chanLabels(secondTable),'Position',[870 170 110 600],'ColumnWidth',{50});

%% Plot all veogBlinks
% Plot Individual Blinks
f2 = figure('Position',[1080 100 750 800],'Color','w');
subplot(2,3,1:2);
blinksVEOG = squeeze(EEG.fnim_blink.blinkEEG(EEG.fnim_blink.options.VEOG,:,:));
blinksVEOG(:,end+1) = mean(blinksVEOG,2);
plot(blinksVEOG(:,end),'r','LineWidth',3)
legend('ERP')
hold on;
plot(blinksVEOG(:,1:end-1),'k')
plot(blinksVEOG(:,end),'r','LineWidth',3)
title(['Individual Blinks in VEOG [Mean Cor. = ' num2str(EEG.fnim_blink.avg_blink_trace_VEOG_meancor) ']']);

% Plot Channel Correlations for ERPs
subplot(2,3,4:5)
plot(EEG.fnim_blink.blinkERP');
hold on;
plot(EEG.fnim_blink.blinkERP(EEG.fnim_blink.options.VEOG,:)','r','LineWidth',3);
title(['ERPs for each channel [Mean Cor. = ' num2str(mean(EEG.fnim_blink.blink_ERP_VEOG_cor)) ']']);
uitable('Parent',f2,'Data',EEG.fnim_blink.blink_ERP_VEOG_cor(firstTable),'ColumnName','r', ...
    'RowName',chanLabels(firstTable),'Position',[500 170 110 600],'ColumnWidth',{50});
uitable('Parent',f2,'Data',EEG.fnim_blink.blink_ERP_VEOG_cor(secondTable),'ColumnName','r', ...
    'RowName',chanLabels(secondTable),'Position',[620 170 110 600],'ColumnWidth',{50});

%% Output com
com = [ com sprintf('%s = pop_summarize_blink_prop(%s);', inputname(1), inputname(1)) ];

end