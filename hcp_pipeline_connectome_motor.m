# Script to run CONNECTOME pipeline for HCP motor task
build_path niak psom
#### SET PIPELINE FILES_IN
# set paths
path_root = '/gs/project/gsf-624-aa/HCP/'; % Root path of you project
path_preproc = [path_root '/fmri_preprocess_all_tasks_niak-fix-scrub_900R/']; % Path of Preprocessed data

# Grab files created by NIAK_PIPELINE_FMRI_PREPROCESS
opt_grab.min_nb_vol = 100;
opt_grab.filter.run = {'motRL'}; % FILTER RUN - Only those runs will be grabbed.
opt_grab.exclude_subject = {'HCP142626','HCP128026'}; % EXCLUDE_SUBJECT
opt_grab.type_files = 'glm_connectome'; % TYPE_FILES - formating FILES based on the purpose of subsequent analysis.
files_in = niak_grab_fmri_preprocess(path_preproc, opt_grab);

# Add brain parcelations to files in
files_in.network = [path_root '/basc_MOTOR_rl-lr_niak-fix-scrub_900R/stability_group/sci120_scg132_scf135/brain_partition_consensus_group_sci120_scg132_scf135.mnc.gz'];

### LIST OF SEEDS
# The next step is to generate a list of seeds. This requires creating a text file.
# We are going to use NIAK’s tool to write comma-separated values (CSV) in a file.

files_in.seeds = [path_preproc filesep 'list_seeds_MOTOR.csv'];
opt_csv.labels_x = { 'MOT_FACE_L' , 'MOT_FACE_R' , 'MOT_HAND_L','MOT_HAND_R' , 'MOT_LEG_L','MOT_LEG_R'}; % The labels for the network
opt_csv.labels_y = { 'index' };
tab = [10;61;32;35;73;15];
niak_write_csv(files_in.seeds,tab,opt_csv);

### SET PIPELINE OPTIONS

# Setup where to store the date
opt.folder_out = [path_root 'connectome_MOTOR_20161203'];
opt.flag_p2p = false; % No parcel-to-parcel correlation values
opt.flag_global_prop = false; % No global graph properties
opt.flag_local_prop  = false; % No local graph properties
opt.flag_rmap = true; % Generate correlation maps

### RUN THE PIPELINE
opt.flag_test = false;
[pipeline,opt] = niak_pipeline_connectome(files_in,opt);
