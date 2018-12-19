% update_erplab_flags() - This function removes and/or adds artifact flags to
%                         epochs from a FNIM lab artifact detection routine.
%                         If artifacts are added (which should be manually),
%                         the flag in ERPLAB is set to 8.
%
% Usage:
%   >>  EEG = update_erplab_flags( EEG, artEpochs, artFlag );
%
% Inputs:
%   EEG         - input EEG dataset (if using GUI, this is current EEG set)
%   artEpochs   - array of epoch indices to compared with
%                 EEG.reject.rejmanual for new and removed artifacts.
%   artFlag     - this is the flag to mark the artifacts with (2 through 8).
%    
% Outputs:
%   EEG         - output dataset with updated artifact flacs
%
% See also: 
%   POP_DETECTDRIFT

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

function EEG = update_erplab_flags( EEG, artEpochs, artFlag )

% Return help if only EEG or no inputs are given
if nargin < 2
	help update_erplab_flags;
	return; 
elseif isempty(EEG.reject.rejmanual)
    if isempty(artEpochs)
        return;
    else
        EEG.reject.rejmanual = false(1,EEG.trials);
        EEG.reject.rejmanualE = false(EEG.nbchan,EEG.trials);
    end
end;

%% Find cleared rejections and new rejections
% turn artEpochs into a vector
temp = zeros(1,length(EEG.reject.rejmanual));
temp(artEpochs) = 1;

% Find cleared rejections
clearedRejections = find(temp == 1 & EEG.reject.rejmanual == 0);
addedRejections = find(temp == 0 & EEG.reject.rejmanual == 1);

%% Remove artifact flags and add new ones
if exist(which('eegplugin_erplab'),'file') && isfield(EEG,'EVENTLIST') % Run markartifacts if ERPLAB installed and EVENTLIST created
    
    for i = 1:length(clearedRejections)

        % Remove artifact flags
        EEG.reject.rejmanual(clearedRejections(i)) = false;
        EEG = markartifacts(EEG,0,1:size(EEG.data,1),[],clearedRejections(i),0,1);

    end
    
    for i = 1:length(addedRejections)
        
        % Add artifact flags
        EEG = markartifacts(EEG,[1 artFlag],1:size(EEG.data,1),[],addedRejections(i),0,0);
        
    end
    
end

end
