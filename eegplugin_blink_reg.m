% eegplugin_blink_reg() - EEGLAB plugin for analysis functions used by
%             the fNiM lab. WARNING: YOU MUST INSTALL THE fNiM TOOLBOX IN
%             THE PLUGIN DIRECTORY. FOR THE TOOLBOX TO WORK, YOU MUST HAVE
%             ERPLAB ALSO INSTALLED.
%
% Usage:
%   >> eegplugin_blink_reg(fig, trystrs, catchstrs);
%
% Inputs:
%   fig        - [integer]  EEGLAB figure
%   trystrs    - [struct] "try" strings for menu callbacks.
%   catchstrs  - [struct] "catch" strings for menu callbacks.
%
% Author: Joshua D. Koen

% Copyright (C) 2015 Joshua D. Koen
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

function vers = eegplugin_blink_reg(fig, trystrs, catchstrs)

    vers = 'fNiM EEGLAB Toolbox - v1.0';
    if nargin < 3
        error('eegplugin_blink_reg requires 3 arguments');
    end;
    
    % add folder to path
    % ------------------
    if ~exist('eegplugin_blink_reg')
        p = which('eegplugin_blink_reg.m');
        p = p(1:findstr(p,'eegplugin_blink_reg.m')-1);
        addpath( p );
    end;
    
    % find import data menu
    % ---------------------
    menuBLINKREG = findobj(fig, 'tag', 'EEGLAB');
    
    % menu callbacks
    % --------------
    % Artifact Detection
    detectDrift = [ trystrs.check_epoch_chanlocs '[EEG, LASTCOM] = pop_detectdrift(EEG); ' catchstrs.new_and_hist ];
    manualInspection = [ trystrs.check_epoch_chanlocs '[EEG, LASTCOM] = pop_manual_artifact_flag(EEG); ' catchstrs.add_to_hist ];
    
    % Blink Correction
    markBlinks = [ trystrs.check_epoch_chanlocs '[EGG, LASTCOM] = pop_mark_blinks(EEG);' catchstrs.add_to_hist ];
    estPropogation = [ trystrs.check_epoch_chanlocs '[EEG, LASTCOM] = pop_est_blink_prop(EEG);' catchstrs.new_and_hist ];
    summarizeProp = [ trystrs.check_epoch_chanlocs '[EEG, LASTCOM] = pop_summarize_blink_prop(EEG);' catchstrs.add_to_hist ]; 
    rmblinkEEG = [  trystrs.check_epoch_chanlocs '[EEG, LASTCOM] = pop_remove_blink_eeg(EEG);' catchstrs.new_and_hist ];
    transferProp = [ trystrs.check_epoch_chanlocs '[fnim_blink, LASTCOM] = pop_transfer_blink_prop( EEG );' catchstrs.add_to_hist ];
    rmblinkERP = '[ERP, LASTCOM] = pop_remove_blink_erp(ERP,fnim_blink);';
   
    % create dropdown tab
    % ------------
    submenu = uimenu( menuBLINKREG,'Label','Blink-Reg','separator','on','tag','FNIM','userdata','startup:on;continuous:off;epoch:on;study:off;erpset:on');
    set(submenu,'position', 7);
    
    % List Artifact Detection functions
    %
    ADmenu = uimenu( submenu,'Label','Artifact Detection','tag','Artifact Detection','separator','off');
    uimenu( ADmenu,'Label','Detect Linear Drift','CallBack',detectDrift);
    uimenu( ADmenu,'Label','Manually Check/Mark Artifacts','CallBack',manualInspection);
        
    % List Blink Correction functions
    %
    BCmenu = uimenu(submenu,'Label','Blink Correction','tag','Blink Correction','separator','off');
    uimenu( BCmenu,'Label','Mark Blinks','CallBack',markBlinks);
    uimenu( BCmenu,'Label','Estimate Blink Propogation','CallBack',estPropogation);
    uimenu( BCmenu,'Label','Summarize Blink Propogation','CallBack',summarizeProp);
    uimenu( BCmenu,'Label','Remove Blink Artifact (EEG)','CallBack',rmblinkEEG);
    uimenu( BCmenu,'Label','Transfer Blink Propogation to workspace','CallBack',transferProp);
    uimenu( BCmenu,'Label','Remove Blink Artifact (ERP)','CallBack',rmblinkERP);
    
end
