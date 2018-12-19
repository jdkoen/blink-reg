% pop_transfer_prop() -  This function transfers the fnim_blink field from
%                        the current EEG to the workspace. 
%
% Usage:
%   >>  [fnim_blink com] = pop_transfer_prop( EEG )
%
% Inputs:
%   EEG         - input EEG dataset (if using GUI, this is current EEG set)
%    
% Outputs:
%   EEG         - output EEG dataset (unchanged from input)
%
% See also:
%    POP_EST_BLINK_PROP, EST_BLINK_PROP, POP_SUMMARIZE_BLINK_PROP

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

function [fnim_blink, com] = pop_transfer_prop( EEG )

com = '';

%% Return help if only EEG or no inputs are given
if nargin < 1
	help pop_transer_prop;
	return; 
end;

%% Check EEG structure for appropriate field and if ERP set exists
if ~isfield(EEG,'fnim_blink')
    error('fnim_blink field has not been created.')
end

%% Transfer the fnim_blink field
fnim_blink = EEG.fnim_blink;

%% Output com
com = [ com sprintf('fnim_blink = pop_transfer_prop(%s);', inputname(1) ) ];

end