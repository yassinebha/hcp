function [] = hcp_pipeline_stability_fir(opt)
% Script to run a preprocessing pipeline analysis on the HCP database.
%
% SYNTAX:
% []= HCP_PIPELEINE_STABILITY_FIR(OPT);
%
% _________________________________________________________________________
% INPUTS:
%
% OPT
%   (structure, optional) with the following fields :
%
%   TASK
%       (string, default 'MOTOR') type of tasks that would be extracted. Possibles tasks are: 'EMOTION',
%       'GAMBLING','LANGUAGE','MOTOR','REST','RELATIONAL','SOCIAL','WM'.
%
%   EXP
%       (string, default 'hcp') type of pipeline preprocessing used .
%       Possibles pipeline : 'NIAK', 'HCP'
%   TRIAL
%       (string, default '') type of trial to estimate the fir response, it depend on th task used.
%   MODEL
%       (structure) see the OPT argument of  HCP_IND_MODEL_<TASK-NAME>_CSV. 
%       The default parameters may work.
%
% _________________________________________________________________________
%
% Script to run a STABILITY_FIR pipeline analysis on the HCP database.
%
% Copyright (c) Pierre Bellec, Yassine Benhajali
% Research Centre of the Montreal Geriatric Institute
% & Department of Computer Science and Operations Research
% University of Montreal, Québec, Canada, 2010-2014
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : fMRI, FIR, clustering, BASC
% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included in
% all copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
% THE SOFTWARE.
% _________________________________________________________________________
%

%%%%%%%%%%%%%%%%%%%%%
%% Parameters
%%%%%%%%%%%%%%%%%%%%%
%% set experimentent
list_fields   = { 'task' , 'exp', 'trial' , 'model'  };
list_defaults = { 'motor', 'hcp', 'rh'    , struct() };
if ischar (opt.task ) &&  ischar(opt.exp)
   opt.task = upper(opt.task);
   if ismember(opt.task,{'EMOTION','GAMBLING','LANGUAGE','MOTOR','REST','RELATIONAL','SOCIAL','WM'}) && ismember(opt.exp,{'hcp','niak'}) && ischar(opt.trial)
      opt = psom_struct_defaults(opt,list_fields,list_defaults);
   else
      error('wrong task, experiement or trial, see help hcp_pipeline_stability_fir')
   end
else 
   error ( 'you must specify the task and the experiment')
end

task  = opt.task;
exp   = opt.exp;
trial = opt.trial;
fprintf ('script to run niak_stability_fir pipeline \n Task: %s \n Experiment: %s\n Trial: %s\n',task,exp,trial)

%% Setting input/output files 
[status,cmdout] = system ('uname -n');
server          = strtrim(cmdout);
if strfind(server,'lg-1r') % This is guillimin
    root_path = '/gs/scratch/yassinebha/HCP/';
    fprintf ('server: %s (Guillimin) \n ',server)
    my_user_name = getenv('USER');
elseif strfind(server,'ip05') % this is mammouth
    root_path = '/mnt/parallel_scratch_ms2_wipe_on_april_2015/pbellec/benhajal/HCP/';
    fprintf ('server: %s (Mammouth) \n',server)
    my_user_name = getenv('USER');
else
    switch server
        case 'peuplier' % this is peuplier
        root_path = '/media/database8/HCP_task/';
        fprintf ('server: %s\n',server)
        my_user_name = getenv('USER');
        
        case 'noisetier' % this is noisetier
        root_path = '/media/database1/';
        fprintf ('server: %s\n',server)
        my_user_name = getenv('USER');
    end
end


%%%%%%%%%%%%%%%%%%%%
%% Grabbing the results from the NIAK fMRI preprocessing pipeline
%%%%%%%%%%%%%%%%%%%%%
opt_g.min_nb_vol = 1;     % The minimum number of volumes for an fMRI dataset to be included. This option is useful when scrubbing is used, and the resulting time series may be too short.
opt_g.min_xcorr_func = 0.5; % The minimum xcorr score for an fMRI dataset to be included. This metric is a tool for quality control which assess the quality of non-linear coregistration of functional images in stereotaxic space. Manual inspection of the values during QC is necessary to properly set this threshold.
opt_g.min_xcorr_anat = 0.5; % The minimum xcorr score for an fMRI dataset to be included. This metric is a tool for quality control which assess the quality of non-linear coregistration of the anatomical image in stereotaxic space. Manual inspection of the values during QC is necessary to properly set this threshold.
opt_g.type_files = 'fir'; % Specify to the grabber to prepare the files for the STABILITY_FIR pipeline
if ismember(opt.trial,{'run1','run2'})
    switch opt.trial
    case 'run1'
        opt_g.filter.run = {[lower(task)(1:2) 'lr']};
    case 'run2'
        opt_g.filter.run = {[lower(task)(1:2) 'rl']};
    end
end
%%%%%%%%%%%%%%Temporary grabber for debugging%%%%%%%%%%%%%%%%%%%%%
%liste_exclude = dir ([root_path 'fmri_preprocess_' upper(task) '_' exp '/anat']);
%liste_exclude = liste_exclude(23:end -1);
%liste_exclude = {liste_exclude.name};
%opt_g.exclude_subject = liste_exclude;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ismember(opt.trial,{'run1','run2'})
   opt_g.exclude_subject ={'HCP168139','HCP123925','HCP130316'};% to be investigated later , it make the pipelne crash, strange artifact in functional images
else
   opt_g.exclude_subject ={'HCP168139'};% to be investigated later , it make the pipelne crash, strange artifact in functional images
end

files_in = niak_grab_fmri_preprocess([root_path 'fmri_preprocess_' upper(task) '_' exp],opt_g); % Replace the folder by the path where the results of the fMRI preprocessing pipeline were stored. 

%%%%%%%%%%%%%%%%%%%%
%% create the csv model for each subject's run
%%%%%%%%%%%%%%%%%%%%
opt_model.exp   = exp;
opt_model.trial = trial;
if ~isempty(opt.model.trial_delay)
   opt_model.trial_delay = opt.model.trial_delay;
end
if ~isempty(opt.model.trial_duration)
   opt_model.trial_duration = opt.model.trial_duration;
end
if ~isempty(opt.model.baseline_delay)
   opt_model.baseline_delay = opt.model.baseline_delay;
end
if ~isempty(opt.model.baseline_duration)
   opt_model.baseline_duration = opt.model.baseline_duration;
end

%% loop over subjects and runs and create individual time events models
data.ind_model = fieldnames(files_in.fmri);
if ismember(opt.trial,{'run1','run2'})
   switch opt.trial
         case 'run1'
            for list = 1:length(data.ind_model)
                opt_model.run = 'lr'; %run1
                path_folder = [ root_path 'fmri_preprocess_' upper(task) '_' exp '/EVs/' data.ind_model{list} '/lr/']; %lr run
                eval([ 'hcp_ind_model_' lower(task) '_csv(path_folder,opt_model)']);
                files_in.timing.(data.ind_model{list}).session1.([lower(task)(1:2) 'LR']) = [path_folder 'hcp_model_intrarun_' lower(opt.task) '_' lower(opt.trial) '.csv'];
            end
         case 'run2'
            for list = 1:length(data.ind_model)
                opt_model.run = 'rl';%run2
                path_folder = [ root_path 'fmri_preprocess_' upper(task) '_' exp '/EVs/' data.ind_model{list} '/rl/']; %rl run
                eval([ 'hcp_ind_model_' lower(task) '_csv(path_folder,opt_model)']);
                files_in.timing.(data.ind_model{list}).session1.([lower(task)(1:2) 'RL']) = [path_folder 'hcp_model_intrarun_' lower(opt.task) '_' lower(opt.trial) '.csv'];
            end
   end
else
   for list = 1:length(data.ind_model)
       opt_model.run = 'lr'; %run1
       path_folder = [ root_path 'fmri_preprocess_' upper(task) '_' exp '/EVs/' data.ind_model{list} '/lr/']; %lr run
       eval([ 'hcp_ind_model_' lower(task) '_csv(path_folder,opt_model)']);
       files_in.timing.(data.ind_model{list}).session1.([lower(task)(1:2) 'LR']) = [path_folder 'hcp_model_intrarun_' lower(opt.task) '_' lower(opt.trial) '.csv'];
       opt_model.run = 'rl';%run2
       path_folder = [ root_path 'fmri_preprocess_' upper(task) '_' exp '/EVs/' data.ind_model{list} '/rl/']; %rl run
       eval([ 'hcp_ind_model_' lower(task) '_csv(path_folder,opt_model)']);
       files_in.timing.(data.ind_model{list}).session1.([lower(task)(1:2) 'RL']) = [path_folder 'hcp_model_intrarun_' lower(opt.task) '_' lower(opt.trial) '.csv'];
   end
end

%%%%%%%%%%%%%
%% Options %%
%%%%%%%%%%%%%

%% BASC
opt.folder_out = [ root_path '/stability_fir_perc_' upper(task) trial '_' exp ]; % Where to store the results
opt.grid_scales = [5:5:50 60:10:200 220:20:400 500:100:900]; % Search in the range 2-900 clusters
% use mstep sacle if exist or leave it empty
mstep_file = [ opt.folder_out filesep 'stability_group/msteps_group.mat']; 
if psom_exist(mstep_file)
   warning ('The file %s exist, I will use MSTEP scale',mstep_file);
   load (mstep_file);
   opt.scales_maps = scales_final;
else
   warning ('The file %s does not exist, I will use the specified scale maps',mstep_file); 
   opt.scales_maps = []; % Usually, this is initially left empty. After the pipeline ran a first time, the results of the MSTEPS procedure are used to select the final scales 
end
% the Number of bootstrap samples at the individual level is 1 intrial run1 and run2 
if ismember(opt.trial,{'run1','run2'})
   opt.stability_fir.nb_samps = 1;
else 
   opt.stability_fir.nb_samps = 100;   % Number of bootstrap samples at the individual level. 100: the CI on indidividual stability is +/-0.1
end

opt.stability_fir.std_noise = 0;     % The standard deviation of the judo noise. The value 0 will not use judo noise. 
opt.stability_group.nb_samps = 500;  % Number of bootstrap samples at the group level. 500: the CI on group stability is +/-0.05
opt.nb_min_fir = 1;    % the minimum response windows number. By defaut is set to 1
opt.stability_group.min_subject = 2; % (integer, default 3) the minimal number of subjects to start the group-level stability analysis. An error message will be issued if this number is not reached.
%% FIR estimation 
opt.name_condition = trial;
opt.name_baseline = 'baseline';
opt.fir.type_norm     = 'fir';       % The type of normalization of the FIR.
opt.fir.time_window   = opt.model.trial_duration;        % The size (in sec) of the time window to evaluate the response
opt.fir.max_interpolation = 7.2;    % --> max 10 vols consécutifs manquants (TR = 0.72s), sinon bloc rejeté, mais ça devrait être irrelevant comme pas de scrubbing ici
opt.fir.time_sampling = 0.72;           % The time between two samples for the estimated response. Do not go below 1/2 TR unless there is a very large number of trials.
opt.fir.nb_min_baseline = 1 ;

%% FDR estimation
opt.nb_samps_fdr = 10000; % The number of samples to estimate the false-discovery rate

%% Multi-level options
opt.flag_ind = false;   % Generate maps/FIR at the individual level
opt.flag_mixed = false; % Generate maps/FIR at the mixed level (group-level networks mixed with individual stability matrices).
opt.flag_group = true;  % Generate maps/FIR at the group level

%%%%%%%%%%%%%%%%%%%%%%
%% Run the pipeline %%
%%%%%%%%%%%%%%%%%%%%%%
opt.flag_test = false; % Put this flag to true to just generate the pipeline without running it. Otherwise the pipeline will start.
opt.psom.qsub_options = '-q sw -l nodes=1:ppn=4,walltime=05:00:00';
pipeline = niak_pipeline_stability_fir(files_in,opt);

%%extra
system(['cp ' mfilename('fullpath') '.m ' opt.folder_out '/.']); % make a copie of this script to output folder
