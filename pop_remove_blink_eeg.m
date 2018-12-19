% pop_remove_blink_eeg() -  This function uses the propogation weights in
%                           fnim_blink to correct for blink artifact in all
%                           epochs without a non-blink artifact. For
%                           each channel, the product of the propogation
%                           weight and the VEOG channel is subtracted from
%                           the channel. This uses the EEG.data field.
%                           After blink artifact is removed, the corrected
%                           and uncorrected data is shown. 
%
% Usage:
%   >>  [EEG, com] = pop_remove_blink_eeg( EEG )
%
% Inputs:
%   EEG         - input EEG dataset 
%
% Outputs:
%   EEG         - output dataset with blink artifact removed from EEG.data
%
% See also:
%    EST_BLINK_PROP, POP_EST_BLINK_PROP, POP_SUMMARIZE_BLINK_PROP

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

function [EEG, com] = pop_remove_blink_eeg( EEG )

% the command output is a hidden output that does not have to
% be described in the header

com = ''; % this initialization ensure that the function will return something
          % if the user press the cancel button            

%% display help if not enough arguments
% ------------------------------------
if nargin < 1
	help pop_remove_blink_eeg;
	return;
end;	

%% Check EEG structure for appropriate field
if ~isfield(EEG,'fnim_blink')
    error('fnim_blink field has not been created. Manually mark blinks first.')
end

%% Extract some variables
VEOG = EEG.fnim_blink.options.VEOG;
HEOG = find(strcmpi({EEG.chanlocs.labels},'HEOG'));
goodEpochs = EEG.fnim_blink.epochs_checked;
b = repmat(EEG.fnim_blink.propogation_weights,1,EEG.pnts);
EEG.fnim_blink.orig_EEG.data = EEG.data;
uncorrectedEEG = EEG.data(:,:,goodEpochs);

%% Remove blink artifact from EEG.data
for i = 1:length(goodEpochs)
    
    % Get current EEG trace
    curEpoch = EEG.data(:,:,goodEpochs(i));
    veogEpoch = curEpoch(VEOG,:,:);
    
    % Loop through channels
    for j = 1:size(curEpoch,1)
        
        if j == VEOG || j == HEOG
            
            continue;
            
        else
            
            curEpoch(j,:,:) = curEpoch(j,:,:) - b(j,:) .* veogEpoch;
            
        end
        
    end
    
    % Store newEpoch
    EEG.data(:,:,goodEpochs(i)) = curEpoch;
    
end

% Get the corrected EEG
EEG.fnim_blink.corrected_EEG.data = EEG.data;
correctedEEG = EEG.data(:,:,goodEpochs);

% Log that correction has been done
EEG.fnim_blink.remove_blink_eeg = true;

% Rebaseline given EEG.times
EEG = pop_epochbin( EEG, [EEG.times(1) EEG.times(end)], 'pre');

% Define electrode range (remove VEOG HEOG)
elecRange = 1:EEG.nbchan;
VEOG = find(strcmpi({EEG.chanlocs.labels},'VEOG'));
HEOG = find(strcmpi({EEG.chanlocs.labels},'HEOG'));
elecRange([VEOG HEOG]) = [];

%% plot the data
eegplot(uncorrectedEEG(elecRange,:,:),'eloc_file',EEG.chanlocs(elecRange),'srate',EEG.srate, ...
    'data2',correctedEEG(elecRange,:,:));

%% Update set name
EEG.setname = [EEG.setname '_rmb'];

%% return the string command for detect drift
% -------------------------
com = [ com sprintf('%s = pop_remove_blink_eeg(%s);', inputname(1), ...
		inputname(1)) ]; 
    
return;
