% detectdrift() - This function detects linear drift in epoched EEG data
%                   and marks epochs with drift as artifacts. This function
%                   is a modified version of REJTREND. The linear drift
%                   detection is conducted with a moving window. 
%
% Usage:
%   >>  [EEG, artEpochs] = detectdrift( EEG, elecRange, maxSlope, ...
%                               RsqThresh, winSize, winStep, artFlag );
%
% Inputs:
%   EEG         - input EEG dataset (if using GUI, this is current EEG set)
%   elecRange   - electrodes/channels to test for linear drift
%   maxSlope    - slope threshold from the linear regression
%   RsqThresh   - minimum R^2 (goodness of fit) for the linear drift to be
%                 considered artifactual.
%   winSize     - the length of the moving window, in milliseconds
%   winStep     - the time between the onset of consecutive time windows,
%                 in milliseconds
%   artFlag     - (optional) the artifact flag to assign epochs with linear
%                 drift (requires ERPLAB)
%    
% Outputs:
%   EEG         - output dataset
%   artEpochs   - array of epochs with a blink detected in at least one
%                 data channel
%
% See also: 
%   POP_DETECTDRIFT, REJTHRESH, POP_REJTHRESH

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

function [rej, rejE ] = detectdrift( EEG, elecRange, maxSlope, ...
                              RsqThresh, winSize, winStep )

% Return help if only EEG or no inputs are given
if nargin < 2
	help detectdrift;
	return; 
end;

%% Run the algorithm to detect slow drift (move to own script)
% ---------------------------------------------------
% Convert window size and step to samples
winSize = ceil(winSize / (1/EEG.srate * 1000));
winStep = ceil(winStep / (1/EEG.srate * 1000));

% Calculate time windows
timeWindows = {[1:winSize]}; % Set first window
while true
    
    % Get the time new window
    tempWindow = timeWindows{end} + winStep;
    
    % Check if valid (store if yes, break if no)
    if max(tempWindow) <= EEG.pnts
        
        timeWindows{end+1} = tempWindow;
        
    else
        
        break;
        
    end
    
end

% This is to avoid divide-by-zero and machine errors.
SST_TOLERANCE = 1000*winSize*1.1921e-07;

% Get X values
x = linspace( 1/winSize,1,winSize);

% Detect drift artifacts
h = waitbar(0,'Detecting drift artifacts...');
fprintf('Detecting drift artifacts in %s channels...\n',num2str(length(elecRange)));
rejE = false(size(EEG.data,1),size(EEG.data,3));
for i = 1:length(elecRange)
    for j = 1:size(EEG.data,3)
        for k = 1:length(timeWindows)
            
            % Update waitbar
            waitbar(i/length(elecRange));
            
            % Define some values
            curChan = elecRange(i);
            curEpoch = j;
            curWin = timeWindows{k};
            
            % Run detection algorithm
            y = EEG.data(curChan,curWin,curEpoch);
            coef = polyfit(x,y,1);   		
			if abs(coef(1)) >= maxSlope
			   	ypred = polyval(coef,x);   % predictions
			   	dev = y - mean(y);          % deviations - measure of spread
			   	SST = sum(dev.^2);          % total variation to be accounted for
                if SST < SST_TOLERANCE      % make sure SST is not too close to zero
                    SST = SST_TOLERANCE;
                end
			   	resid = y - ypred;              % residuals - measure of mismatch
			   	SSE = sum(resid.^2);           % variation NOT accounted for
                Rsq = 1 - SSE/SST;             % percent of error explained
				if Rsq > RsqThresh
					rejE( curChan, curEpoch ) = true;
                end
            end
            
        end
    end
end
close(h);
rej = sum(rejE) > 0;
fprintf('%s/%s epochs marked with drift artifacts\n',num2str(sum(rej)),num2str(size(EEG.data,3)));

end
