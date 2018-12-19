% estimate_blink_prop() - This function estimates blink propogation on
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
%                         This is the subroutine for
%                         pop_est_blink_prop()
%
% Usage:
%   >>  EEG = est_blink_prop( EEG, VEOG, fwhmWin, blinkWin, baseWin )
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
%   POP_EST_BLINK_PROP, POP_SUMMARIZE_BLINK_PROP

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

function EEG = est_blink_prop( EEG, VEOG, fwhmWin, blinkWin, baseWin )
                                
%% Return help if only EEG or no inputs are given
if nargin < 2
	help est_blink_prop;
	return; 
end;

%% Check EEG structure for appropriate field
if isfield(EEG,'fnim_blink')
    if ~isfield(EEG.fnim_blink,'epochs_checked') || ~isfield(EEG.fnim_blink,'epochs_with_blinks')
        error('Must first manually mark blinks.');
    end
else
    error('fnim_blink field has not been created. Manually mark blinks first.')
end

%% Store options in fnim_blink
EEG.fnim_blink.options.VEOG = VEOG;
EEG.fnim_blink.options.fwhmWin = fwhmWin;
EEG.fnim_blink.options.blinkWin = blinkWin;
EEG.fnim_blink.options.baseWin = baseWin;

%% Convert input to samples, not time
fwhmSamples = fwhmWin / (1/EEG.srate * 1000); % Convert FWHM to samples
blinkSample = (blinkWin / (1/EEG.srate * 1000)); % Convert blinkWin to samples
baseSample = baseWin / (1/EEG.srate * 1000); % Convet baseWin to samples

%% Initialize some variables
% Blink EEG (Channels, Time, Epoch)
blinkEEG = zeros(EEG.nbchan,baseSample + blinkSample,1);
blinkCount = 1; % Only starts when first blnk is book

% Get the blinks vector from fnim_blink field
blinkEpochs = EEG.fnim_blink.epochs_with_blinks;

% Create variables for storing data
fwhmBadWin = []; % Store epochs with bad FWHM window
fwhmBadValue = []; % Store epochs with bad FWHM values
fwhmValues = []; % Store FWHM value (nan if cannot be calculated)
badWindowWidth = []; % Could not extract blink window (window width plus baseline)
goodEpochs = []; % Store epochs that will be used to calculate blink ERP
blinkrej = false(1,length(blinkEpochs)); % Logical vector for clearing bad FWHM epochs

%% Check blinkEpochs for FWHM criteria
fprintf('Checking FWHM criterion...')

for i = 1:length(blinkEpochs)
    
   % Get the current blink trace
   curBlink = EEG.data(VEOG,:,blinkEpochs(i));
    
   % Find the maximum value of the epoch
   peakVoltage = max(curBlink);
   peakSample = find(curBlink == peakVoltage);
   halfAmp = peakVoltage / 2;
    
   % Start at peak, and find width at half amplitude
   w = 1;
   badBlink = false;
   while true
       
       % Determine samples to draw from, and check if in allowable range
       sampleL = peakSample - w;
       sampleR = peakSample + w;
       if sampleL < 1 || sampleR > EEG.pnts
           fwhmBadWin(end+1) = blinkEpochs(i);
           blinkrej(i) = true;
           badBlink = true;
           fwhmValues(end+1) = nan;
           break;
       end
       
       % Estimate the left and right amplitude
       ampL = curBlink(sampleL);
       ampR = curBlink(sampleR);
       
       % Check if both are below half amplitude (this will reuslt in a
       % one-step below half amplitude)
       if ampL < halfAmp && ampR < halfAmp
           % Subtract 1 from W to find half amplitude where both samples are just
           % above halfAmp
           w = w - 1;
           break;
       else
           w = w + 1;
       end
       
   end
   
   if ~badBlink
       
       % Multiply w by 2 and add 1 to get the actual width
       width = w * 2 + 1;
       fwhmValues(end+1) = width;
       
       % Check if in FWHM range
       if width < fwhmSamples(1) || width > fwhmSamples(2)
           blinkrej(i) = true;
           fwhmBadValue(end+1) = blinkEpochs(i);
       end
       
   end
   
end

% Store info in EEG.fnim_blink
EEG.fnim_blink.fwhm_values = fwhmValues;
EEG.fnim_blink.blinks_bad_fwhm_window = fwhmBadWin;
EEG.fnim_blink.blinks_bad_fwhm_value = fwhmBadValue;

%% Extract blinks
% Calculate some values
blinkWidth = ceil(blinkSample/2);
blinkCount = 1;

% Loop through blink Epochs and extract the blinks
for i = 1:length(blinkEpochs)
    
    % Skip this step if blinkEpochs exlcuded
    if ismember(blinkEpochs(i),fwhmBadWin) || ismember(blinkEpochs(i),fwhmBadValue)
        continue;
    end
    
    % Get the current epoch and VEOG channels
    curEpoch = EEG.data(:,:,blinkEpochs(i));
    curVEOG = curEpoch(VEOG,:,:);
    
    % Get the maximum (absolute value) of the current epoch in VEOG
    peakSample = find(max(curVEOG) == curVEOG);
    
    % Check if blinkWin is within range
    if rem(blinkSample,2) == 1
        blinkRange = (peakSample - blinkWidth - baseSample + 1):(peakSample + blinkWidth - 1);
    else
        blinkRange = (peakSample - blinkWidth - baseSample + 1):(peakSample + blinkWidth);
    end
    if blinkRange(1) < 1 || blinkRange(end) > EEG.pnts
        
        badWindowWidth(end+1) = blinkEpochs(i);
        blinkrej(i) = true;
        continue;
        
    else
        
        % Log the good epoch
        goodEpochs(end + 1) = blinkEpochs(i);
        
        % Store blink in blinks
        blinkEEG(:,:,blinkCount) = curEpoch(:,blinkRange,:);
        
        %Update counter
        blinkCount = blinkCount + 1;
        
    end
    
end

% Store EPOCHS with windows out of range
EEG.fnim_blink.blinks_bad_window_width = badWindowWidth;
EEG.fnim_blink.epochs_for_blink_erp = goodEpochs;

%% Baseline correct each blink Epoch
for i = 1:size(blinkEEG,1)
    for j = 1:size(blinkEEG,3)
        blinkEEG(i,:,j) = blinkEEG(i,:,j) - mean(blinkEEG(i,1:baseSample,j));
    end
end

%% Store EEG and calculate ERP
EEG.fnim_blink.blinkEEG = blinkEEG;
blinkERP = mean(blinkEEG,3);
EEG.fnim_blink.blinkERP = blinkERP;

%% Estimate propogration weights
if isempty(EEG.fnim_blink.epochs_for_blink_erp)
    error('No blinks were included in blink ERP. Change parameters.');
else
    fprintf('Estimating blink propogation...');
    ERP = EEG.fnim_blink.blinkERP;
    propWeight = zeros(size(ERP,1),1);
    for i = 1:size(ERP,1)
        b = glmfit(ERP(VEOG,baseSample+1:end),ERP(i,baseSample+1:end),'normal');
        propWeight(i) = b(2);
    end
    EEG.fnim_blink.propogation_weights = propWeight;
    fprintf('DONE\n');
end

%% Calculate correlations between blinks
blinkVEOG = squeeze(EEG.fnim_blink.blinkEEG(VEOG,baseSample+1:end,:));
blinkCor = corr(blinkVEOG);
filter = true(size(blinkCor));
filter(triu(filter)) = false;
EEG.fnim_blink.blink_trace_VEOG_cormat = blinkCor;
EEG.fnim_blink.avg_blink_trace_VEOG_meancor = mean(blinkCor(filter));

%% Calculate Correlations between channels for blink ERPs
blinkERP = EEG.fnim_blink.blinkERP(:,baseSample+1:end);
blinkERPcor = corr(blinkERP');
EEG.fnim_blink.blink_ERP_cormat = blinkERPcor;
EEG.fnim_blink.blink_ERP_VEOG_cor = blinkERPcor(:,VEOG);

end


