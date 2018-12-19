% pop_est_blink_prop() -  TThis function estimates blink propogation on
%                         epochs that have no other aritfacts. Given the
%                         marked blink epochs in EEG.fnim_blink, the blink
%                         ERPs are created and regression is used to
%                         determine weights. 
%                         
%                         Blinks are only included in the ERP if (1) they
%                         are in the FWHM range and (2) if the blink window
%                         can be extracted. The blink window is the width
%                         of blinkWin/2 around the peak of a blink
%                         (detected with a max value function), and the
%                         baseline window is the baseWin period prior to
%                         the blink window from blinkWin. Blinks are
%                         aligned to the baseline period. 
%
% Usage:
%   >>  [EEG, com] = pop_est_blink_prop( EEG, VEOG, fwhmWin, blinkWin, baseWin )
%
% Inputs:
%   EEG         - input EEG dataset (if using GUI, this is current EEG set)
%   VEOG        - channel index for the VEOG channel
%   fwhmWin     - lower and upper limits of the full-width at half-maximum
%                 from the peak of a blink. 
%   blinkWin    - size of the window, in milliseconds, around the peak of a
%                 blink
%   baseWin     - length of period prior to blink (prior to peakValue - 1/2
%                 * blinkWin) to reference each blink EEG. (in
%                 milliseconds)
% Outputs:
%   EEG         - output dataset with additions to fnim_blink field
%
% See also:
%    EST_BLINK_PROP, POP_SUMMARIZE_BLINK_PROP

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

function [EEG, com] = pop_est_blink_prop( EEG, VEOG, fwhmWin, blinkWin, baseWin )

% the command output is a hidden output that does not have to
% be described in the header

com = ''; % this initialization ensure that the function will return something
          % if the user press the cancel button            

%% display help if not enough arguments
% ------------------------------------
if nargin < 1
	help pop_est_blink_prop;
	return;
end;	

%% pop up window
% -------------
if nargin < 2
    
    % Define the prompts
	promptstr    = { ...
        { 'style' 'text' 'string' 'VEOG Channel' }, ...
        { 'style' 'edit' 'string' '60' }, ...
        { 'style' 'text' 'string' 'FWHM Lower Threshold (in ms)' }, ...
        { 'style' 'edit' 'string' '80' }, ...
        { 'style' 'text' 'string' 'FWHM Upper Threshold (in ms)' }, ...
        { 'style' 'edit' 'string' '250' }, ...
        { 'style' 'text' 'string' 'Blink Window (in ms)' }, ...
        { 'style' 'edit' 'string' '300' }, ...
        { 'style' 'text' 'string' 'Baseline Window (in ms)' }, ...
        { 'style' 'edit' 'string' '50' }, ...
        };
    
    % Define geomery
    g1 = [2 1];
    geometry = { g1 g1 g1 g1 g1 };
    
    % Make GUI
    result = inputgui('geometry',geometry,'uilist',promptstr, ...
        'helpcom', 'pophelp(''pop_est_blink_prop'')', ...
        'title', 'Estimate Blink Propogation == pop_est_blink_prop()' );
    
    % If cancel hit (result is empty)
    if isempty(result)
        return;
    end
    
    % Retrieve parameters for options
    VEOG = str2double(result{1});
    fwhmWin = [str2double(result{2}) str2double(result{3})];
    blinkWin = str2double(result{4});
    baseWin = str2double(result{5});
        
elseif nargin < 6 % Set default parameters if not all are given
    
    error('Must provide all inputs.')
    
end;

%% Call the function
EEG = est_blink_prop( EEG, VEOG, fwhmWin, blinkWin, baseWin );
          
%% Call pop_summarize_blink_prop
EEG = pop_summarize_blink_prop( EEG );

%% return the string command for detect drift
% -------------------------
com = [ com sprintf('%s = pop_est_blink_prop(%s,%s);', inputname(1), ...
		inputname(1), vararg2str({VEOG,fwhmWin,blinkWin,baseWin})) ]; 
    
return;
