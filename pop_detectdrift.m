% pop_detectdrift() -  This function detects linear drift in epoched EEG data
%                   and marks epochs with drift as artifacts. This function
%                   is a modified version of POP_REJTREND. The linear drift
%                   detection is conducted with a moving window.    
%
% Usage:
%   >>  [EEG, com] = pop_detectdrift( EEG, elecRange, maxSlope, ...
%                         RsqThresh, winSize, winStep, artFlag 
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
%
% See also:
%    POP_DETECTDRIFT, REJTHRESH, POP_REJTHRESH

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

function [EEG, com] = pop_detectdrift( EEG, elecRange, maxSlope, ...
                        RsqThresh, winSize, winStep, artFlag )

% the command output is a hidden output that does not have to
% be described in the header

com = ''; % this initialization ensure that the function will return something
          % if the user press the cancel button            

%% display help if not enough arguments
% ------------------------------------
if nargin < 1
	help pop_detectdrift;
	return;
end;	

%% pop up window
% -------------
if nargin < 2
    
    % Set up the options and default values
    commandchans = [ 'tmpchans = get(gcbf, ''userdata'');' ...
                     'tmpchans = tmpchans{1};' ...
                     'set(findobj(gcbf, ''tag'', ''chantype''), ''string'', ' ...
                     '       int2str(pop_chansel( tmpchans )));' ...
                     'clear tmpchans;' ];
    commandtype = ['tmptype = get(gcbf, ''userdata'');' ...
                   'tmptype = tmptype{2};' ...
                   'if ~isempty(tmptype),' ...
                   '    [tmps,tmpv, tmpstr] = listdlg2(''PromptString'',''Select type(s)'', ''ListString'', tmptype);' ...
				   '    if tmpv' ...
				   '        set(findobj(''parent'', gcbf, ''tag'', ''chantype''), ''string'', tmpstr);' ...
				   '    end;' ...
                   'else,' ...
                   '    warndlg2(''No channel type'', ''No channel type'');' ...
                   'end;' ...
				   'clear tmps tmpv tmpstr tmptype tmpchans;' ];
               
    % Define the prompts
	promptstr    = { ...
        { 'style' 'text' 'string' 'Channel type(s) or indices' }, ...
        { 'style' 'edit' 'string' '' 'tag' 'chantype' }, ...
        { 'style' 'pushbutton' 'string' '... types' 'callback' commandtype } ...
        { 'style' 'pushbutton' 'string' '... channels' 'callback' commandchans }, ...
        { 'style' 'text' 'string' 'Slope threshold (uV/time window)' }, ...
        { 'style' 'edit' 'string' '50' }, ...
        { 'style' 'text' 'string' 'R-squared threshold (0 to 1)' }, ...
        { 'style' 'edit' 'string' '.3' }, ...
        { 'style' 'text' 'string' 'Time Window Length (in ms)' }, ...
        { 'style' 'edit' 'string' num2str(EEG.pnts * (1/EEG.srate) * 1000) }, ...
        { 'style' 'text' 'string' 'Time Window Step (in ms)' }, ...
        { 'style' 'edit' 'string' '10' }, ...
        { 'style' 'text' 'string' 'Artifact Flag (for ERPLAB; 2 to 8)' }, ...
        { 'style' 'edit' 'string' '2' }, ...
        };
    
    % Define geomery
    g1 = [2 1 1 1];
    g2 = [2 1.5];
    geometry = { g1 g2 g2 g2 g2 g2};

    % channel types
    % -------------
    if isfield(EEG.chanlocs, 'type'), 
        tmpchanlocs = EEG(1).chanlocs;
        alltypes = { tmpchanlocs.type };
        indempty = cellfun('isempty', alltypes);
        alltypes(indempty) = '';
        try, 
            alltypes = unique_bc(alltypes);
        catch, 
            alltypes = '';
        end;
    else
        alltypes = '';
    end;
    
    % channel labels
    % --------------
    if ~isempty(EEG.chanlocs)
        tmpchanlocs = EEG(1).chanlocs;        
        alllabels = { tmpchanlocs.labels };
    else
        for index = 1:EEG(1).nbchan
            alllabels{index} = int2str(index);
        end;
    end;
    
    % Make GUI
    result = inputgui('geometry',geometry,'uilist',promptstr, ...
        'helpcom', 'pophelp(''pop_detectdrift'')', ...
        'title', 'Detect Linear Drift == pop_detectdrift()', ...
        'userdata', { alllabels alltypes } );
    
    % If cancel hit (result is empty)
    if isempty(result)
        return;
    end
    
    % Sort the results into the appropriate variables, and check input for
    % errors
    % Electrodes
    if ~isempty(result{1})
        if ~isempty(str2num(result{1})), elecRange = str2num(result{1});
        else                             elecRange = parsetxt(result{1}); 
        end;
    end;
    
    % Slope threshold
    maxSlope     = str2double(result{2});
    
    % R-Squared Threshold
    RsqThresh    = str2double(result{3});
    if RsqThresh < 0 || RsqThresh > 1
        error('R-Squared must be between 0 and 1.');
    end
    
    % Window Size
    winSize      = str2double(result{4});
    if winSize > (EEG.pnts * (1/EEG.srate) * 1000)
        error('Size of the window is larger than the epoch length.')
    end
    
    % Window Step
    winStep      = str2double(result{5});
    
    % Artifact flag
    artFlag      = str2double(result{6});
    if artFlag == 1
        artFlag = 1;
    elseif artFlag > 8
        error('Artifact flag must be between 2 and 8.')
    else
        artFlag = [1 artFlag];
    end
        
elseif nargin < 7 % Set default parameters if not all are given
    
    error('Must provide all inputs.')
    
end;

%% Call the function
[rej, rejE] = detectdrift( EEG, elecRange, maxSlope, ...
                                RsqThresh, winSize, winStep );

%% If EEG.reject is empty, make it have a length of the number of trials
if isempty(EEG.reject.rejmanual)
    EEG.reject.rejmanual = false(1,EEG.trials);
    EEG.reject.rejmanualE = false(EEG.nbchan,EEG.trials);
    artEpochs = find(rej);
else
    artEpochs = find(rej | EEG.reject.rejmanual);
end

%% Mark the Epochs with artifact flags if ERPLAB installed and EVENTLIST created
if exist(which('eegplugin_erplab'),'file') && isfield(EEG,'EVENTLIST') % Run markartifacts if ERPLAB installed and EVENTLIST created
    for i = 1:length(rej)
        
        if rej(i)

            % Find the bad channels
            badChans = find(rejE(:,i));

            % Mark in EEG
%             EEG = markartifacts(EEG,[1 artFlag],1:EEG.nbchan,badChans,i,0,1);
            EEG = markartifacts(EEG,[1 artFlag],1:EEG.nbchan,badChans,i,0,0); % The last 0 indicates that artifact info should be synced
            
        end

    end
    
end

%% return the string command for detect drift
% -------------------------
EEG.setname = [ EEG.setname '_drift' ];

%% return the string command for detect drift
% -------------------------
com = [ com sprintf('%s = pop_detectdrift(%s,%s);', inputname(1), ...
		inputname(1), vararg2str({elecRange, maxSlope, RsqThresh, winSize, winStep, artFlag})) ]; 
    
return;
