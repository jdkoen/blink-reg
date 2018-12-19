% pop_mark_blinks() -  This function plots the data excluding currently
%                      marked artifacts. The purpose of this is to exclude
%                      bad epochs, and identify epochs with blinks from
%                      'good' epochs. 
%
% Usage:
%   >>  [EEG, com] = pop_manual_artifact_flag( EEG, artFlag ) 
%
% Inputs:
%   EEG        - current dataset structure or structure array
%    
% Outputs:
%   EEG        - current dataset structure or structure array. Note that
%                this function adds a EEG.fnim_blink structure to EEG. 
%
% See also:
%    POP_EEGPLOT, EEGPLOT

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

function [EEG, com] = pop_mark_blinks( EEG ) 

% the command output is a hidden output that does not have to
% be described in the header

com = ''; % this initialization ensure that the function will return something
          % if the user press the cancel button            

%% display help if not enough arguments
% ------------------------------------
if nargin < 1
	help pop_mark_blinks;
	return;
end;	

%% pop up window
% -------------
if nargin < 2
    
    % Define the prompts
	promptstr    = { ...
        { 'style' 'text' 'string' 'VEOG Channel' }, ...
        { 'style' 'edit' 'string' '60' }, ...
        };
    
    % Define geometry
    geometry = { [2 2] };
    
    % Make GUI
    result = inputgui('geometry',geometry,'uilist',promptstr, ...
        'helpcom', 'pophelp(''pop_detectdrift'')', ...
        'title', 'Mark Blink Epochs == pop_mark_blinks()');
    
    % Get result
    VEOG = parsetxt(result{1});
    if length(VEOG) > 1
        error('Only one channel can be selected.')
    else
        VEOG = str2double(VEOG);
    end
    
end
    
%% Chech if ERPLAB installed and EVENTLIST created
% ------------------------------------
if exist(which('eegplugin_erplab'),'file')
   if ~isfield(EEG,'EVENTLIST')
       error('Must create EVENTLIST structure.')
   end
else
    error('Must have the ERPLAB plugin installed.')
end

%% Remove artifacts from current EEG
% ------------------------------------
fprintf('Excluding %s/%s epochs from blink detect.\n', ...
    num2str(sum(EEG.reject.rejmanual)), ...
    num2str(length(EEG.reject.rejmanual)));

%% Mark Epochs corrently labeled as blinks
% ------------------------------------
if isfield(EEG,'fnim_blink') % Make winrej structure
    if isfield(EEG.fnim_blink,'epochs_with_blinks') && isfield(EEG.fnim_blink,'epochs_checked')
        rej = false(1,length(EEG.fnim_blink.epochs_checked));
        rejE = rej;
        rej(ismember(EEG.fnim_blink.epochs_checked,EEG.fnim_blink.epochs_with_blinks)) = true;
        winrej = trial2eegplot(rej,rejE,EEG.pnts,[.9 .1 .1]);
    end
else
    winrej = [];
end

%% Plot the EEG data with eegplot() and mark epochs
% ------------------------------------
cmd = [ ...
    'EEG.fnim_blink.epochs_checked = find(~EEG.reject.rejmanual);' ...
    'tmprej = eegplot2trial( TMPREJ, EEG.pnts, length(EEG.fnim_blink.epochs_checked));' ...
    'EEG.fnim_blink.epochs_with_blinks = EEG.fnim_blink.epochs_checked(logical(tmprej));'
    ];
eegplot(EEG.data(VEOG,:,~EEG.reject.rejmanual),'eloc_file',EEG.chanlocs(VEOG),'srate',EEG.srate, ...
    'command',cmd,'butlabel','Mark Blinks','wincolor',[ .9 .1 .1],'winrej',winrej);

% cmd = [ ...
%     'EEG.fnim_blink.epochs_checked = find(~EEG.reject.rejmanual);' ...
%     'tmprej = eegplot2trial( TMPREJ, EEG.pnts, length(EEG.fnim_blink.epochs_checked));' ...
%     'EEG.fnim_blink.epochs_with_blinks = EEG.fnim_blink.epochs_checked(logical(tmprej));'];

%% return the string command for detect drift
% -------------------------
com = [ com sprintf('%s = pop_mark_blinks(%s);', inputname(1), ...
		inputname(1))]; 

end
