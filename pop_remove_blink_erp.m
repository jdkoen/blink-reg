% pop_remove_blink_erp() -  This function uses the propogation weights in
%                           fnim_blink to correct for blink artifact in all
%                           channels in the ERP set (excluding HEOG and
%                           VEOG channels). The product of the propogation
%                           weight and the VEOG channel is subtracted from
%                           each channel. This uses the ERP.bindata field.
%                           This is done separately for each bin. Thus, it
%                           is important to do this AFTER the final bin
%                           operation has been completed. Baseline
%                           correction is performed on the ERPs after the
%                           ocular artifact has been removed. 
%
% Usage:
%   >>  [ERP, com] = pop_remove_blink_eeg( ERP, fnim_blink )
%
% Inputs:
%   ERP         - input ERP dataset 
%   fnim_blink  - fnim_blink structure loaded into the workspace
%                 (transfered from an EEG set with POP_TRANSFER_PROP)
%
% Outputs:
%   ERP         - output dataset with blink artifact removed from ERP.bindata
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

function [ERP, com] = pop_remove_blink_erp( ERP, fnim_blink )

% the command output is a hidden output that does not have to
% be described in the header

com = ''; % this initialization ensure that the function will return something
          % if the user press the cancel button            

%% display help if not enough arguments
% ------------------------------------
if nargin < 1
	help pop_remove_blink_erp;
	return;
end;	

%% Extract some variables
VEOG = fnim_blink.options.VEOG;
HEOG = find(strcmpi({ERP.chanlocs.labels},'HEOG'));
b = repmat(fnim_blink.propogation_weights,1,ERP.pnts);
fnim_blink.orig_ERP.data = ERP.bindata;

%% Remove blink artifact from ERP.bindata
for i = 1:size(ERP.bindata,3) % Loop through each bin
    
    % Get current EEG trace
    curERP = ERP.bindata(:,:,i);
    veogERP = curERP(VEOG,:,:);
    
    % Loop through channels
    for j = 1:size(curERP,1)
        
        if j == VEOG || j == HEOG
            
            continue;
            
        else
            
            curERP(j,:,:) = curERP(j,:,:) - b(j,:) .* veogERP;
            
        end
        
    end
    
    % Store newEpoch
    ERP.bindata(:,:,i) = curERP;
    
end

% Get the corrected EEG
fnim_blink.corrected_ERP.data = ERP.bindata;

% Log that correction has been done
fnim_blink.remove_blink_erp = true;

% Rebaseline given EEG.times
ERP = pop_blcerp( ERP , 'Baseline', 'pre', 'Saveas', 'on' );
    
end
