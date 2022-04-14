
% Summary:
% Script to convert EEG raw (.bdf) and preproc (.set) into BIDS format

% Status:
% Under Development

% Notes:
% RETT project

% Author(s):
% Kevin Prinsloo

% Editor(s):
%

%% Prepare Workspace
% clearvars
% close all
% clc

% Initialise Path Variables
addpath 'C:\Users\kevin\Chimera_Study_Desktop\eeglab_current\eeglab14_1_2b';
eeglab
close all
ft_defaults

addpath 'C:\Users\kevin\Box\RCBI_Server_Storage\aa_tufi\Tufi_Guthub\scr'
data_path = (['C:\Users\kevin\Box\RETT_Standard_IndivDiffs_paper\RAW_DATA\ALL']);
bidsroot = 'C:\Users\kevin\Box\RETT_BIDS'; % where output will be saved

%% Initialise Subject Variables
listing = dir([data_path,'\']);
file_listings = {listing.name};
file_listings(cellfun('length', file_listings)<3) = [];
file_orig = file_listings;
file_number = numel(file_orig);

epoch_window = [-1000 1000]; %tb. 2020 changed it to 1second befor and 1second after was -300 to 700 but initially it was [-100 800]

%-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
% >> Main function used for transformation data2bids
%-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

% For each dataset, there is an entry in the "datainfo" table with the following content
% 1) the name of the dataset
% 2) the level of sedation at which the dataset was acquired (1 = baseline, 2 = mild sedation, 3 = moderate sedation, 4 = recovery)
% 3) the concentration of propofol measured in blood plasma at that level (in microgram/litre)
% 4) the average reaction time measured in a speeded two-choice response task administered at that level (in milliseconds)
% 5) the number of correct responses in that task (out of a max of 40)
% trigs = {'3','5','7','9','11','13'}; %3=450ms standard %5=450ms deviant %7=900ms standard %9=900ms deviant

% Load CVS file with subject information (e.h. age, gender, clinical scores, etc.)
%-------------------------------------------------------------------------------------------
tab = readtable('C:\Users\kevin\Box\RETT_Standard_IndivDiffs_paper\RAW_DATA\ALL_subject_demo.csv');
channels_cephalic = 64;

% PReallocation
pInfo = [];
subject_BIDS_ID = cell(length(file_listings),1);
which_grp_lst = cell(length(file_listings),1);
pInfo_lst = cell(length(file_listings),8);

for subject_Idx = 1:length(file_listings)
    subject_ID = file_listings{subject_Idx};
        
    Sub_strPadded = sprintf( '%03d',subject_Idx);
    BIDS_sub_ID_idx = ['Subject',Sub_strPadded];
    
    % Find age and gender in CVS table
    IDidx = find(tab.Var1 == str2double(subject_ID));
    age = tab.Var2(IDidx);
    gender = tab.Var3{IDidx};
    RSSS = tab.Var4(IDidx);
    Mutations = tab.Var5{IDidx};
    Seizures = tab.Var6{IDidx};
    Medications = tab.Var7{IDidx};
    
    if str2double(subject_ID(1)) > 1
        which_group = 'RETT';
    else
        which_group = 'TD';
    end
    which_grp_lst{subject_Idx} = which_group;
    subject_BIDS_ID{subject_Idx} = ['Subject',Sub_strPadded];
    
    %pInfo_lst{'participant_id', 'gender'   'age'   'group' 'RSSS' 'Mutations' 'Seizures' 'Medications';
    %BIDS_sub_ID_idx,  gender, age, which_group, RSSS, Mutations, Seizures, Medications}
    
    pInfo_lst{1,1} = 'participant_id';
    pInfo_lst{1,2} = 'gender';
    pInfo_lst{1,3} = 'age';
    pInfo_lst{1,4} = 'group';
    pInfo_lst{1,5} = 'RSSS';
    pInfo_lst{1,6} = 'Mutations';
    pInfo_lst{1,7} = 'Seizures';
    pInfo_lst{1,8} = 'Medications';
    
    pInfo_lst{subject_Idx+1,1} = BIDS_sub_ID_idx;
    pInfo_lst{subject_Idx+1,2} = gender;
    pInfo_lst{subject_Idx+1,3} = sprintf('%.1f',age);
    pInfo_lst{subject_Idx+1,4} = which_group;
    pInfo_lst{subject_Idx+1,5} = RSSS;
    pInfo_lst{subject_Idx+1,6} = Mutations;
    pInfo_lst{subject_Idx+1,7} = Seizures;
    pInfo_lst{subject_Idx+1,8} = Medications;
    
end

for subject_Idx = 1:length(file_listings)
    subject_ID = file_listings{subject_Idx};
    disp(subject_ID)
    
    % general information for dataset_description.json file
    % -----------------------------------------------------
    generalInfo.Name = 'Auditory Duration MMN';
    generalInfo.License = 'ODbL (https://opendatacommons.org/licenses/odbl/summary/)';
    generalInfo.Authors = {'Brima, T.', 'Molholm, S.', 'Beker, S.', 'Prinsloo, K. D.', 'Butler, J. S.', 'Djukic, A.', 'Freeman, E. G.', 'Foxe, J. J.'};
    generalInfo.HowToAcknowledge = 'preprint DOI []';
    generalInfo.Funding = {' '};
    generalInfo.ReferencesAndLinks = {' '};
    generalInfo.DatasetDOI = ' ';
            
    dat = load([data_path,'\',subject_ID,'\',subject_ID,'_mat','\',subject_ID,'.mat']);
    EEG = dat.EEG; clear dat
    % sort out missing channel in data
    load('E:\aa_Tufi_Copy\chanlocs_64.mat');
    %EEG.chaninfo =
    EEG.chanlocs = chanlocs_64;
    EEG.data = EEG.data(1:64,:);
    EEG.nbchan = 64;
    
    % Save loaded EEG .mat file into set and load again ->> must be a simpler way though
    if exist( [data_path,'\',subject_BIDS_ID{subject_Idx},'\',subject_BIDS_ID{subject_Idx},'-set','\'],'dir') == 0
        mkdir([data_path,'\',subject_BIDS_ID{subject_Idx},'\',subject_BIDS_ID{subject_Idx},'-set','\']);
    end
    filename = [data_path,'\',subject_BIDS_ID{subject_Idx},'\',subject_BIDS_ID{subject_Idx},'-set','\',subject_BIDS_ID{subject_Idx}];
    filetype = '.set';
    save([filename,filetype],'EEG','-v7.3'); clear filename filetype EEG
    
    % %% OPTIONAL: Load set file now and check it is working
    %dat = load('-mat',[data_path,'\',subject_BIDS_ID{subject_Idx},'\',subject_ID,'-set','\',subject_ID,'.set']);
    %EEG = dat.EEG; clear dat
    
    if exist( [bidsroot,'\','sub-',subject_BIDS_ID{subject_Idx},'\','ses-1','\','eeg','\'],'dir') == 0
        mkdir([bidsroot,'\','sub-',subject_BIDS_ID{subject_Idx},'\','ses-1','\','eeg','\']);
    end
    
    % Now do cfg file
    %---------------------------------------------------------------------
    cfg = [];
    cfg.method    =  'copy';   % copying would have also been an option, but the BrainVision format is more widely supported
    cfg.datatype  = 'eeg';
    
    % specify the input file name, here we are using the same file for every subject
    %cfg.dataset   = 'C:\Users\kevin\Box\RCBI_Server_Storage\aa_tufi\Tufi_Guthub\Eeglab_data.set'; %'Eeglab_data.set';
    cfg.dataset   = ([data_path,'\',subject_BIDS_ID{subject_Idx},'\',subject_BIDS_ID{subject_Idx},'-set','\',subject_BIDS_ID{subject_Idx},'.set']);
    
    % specify the output directory
    cfg.bidsroot  = bidsroot;
    cfg.sub       = subject_BIDS_ID{subject_Idx};
    cfg.run       = '1'; % this is a number - but we have already concatinated runs - this could be different condtions i.e. SOA if you were to seperate the data
    cfg.ses       = '1';
    
    % specify the information for the participants.tsv file
    % this is optional, you can also pass other pieces of info
    cfg.participants.participant_id = subject_BIDS_ID{subject_Idx}; %'unique participant identifier';
    cfg.participants.age = age;
    cfg.participants.sex = gender;
    cfg.participants.group = which_group;
    
    % provide the mnemonic and long description of the task
    %-----------------------------------------------------------------
    
    cfg.InstitutionName             = 'University of Rochetser';
    cfg.InstitutionalDepartmentName = 'The Frederick J. and Marion A. Schindler Cognitive Neurophysiology Laboratory, The Del Monte Institute for Neuroscience , Department of Neuroscience';
    cfg.InstitutionAddress          = 'University of Rochester Medical Center, 601 Elmwood Avenue, Box 603, KMRB G.9602, Rochester, NY 14642, USA';
    
    cfg.TaskName = 'MMN';
    cfg.TaskDescription = 'Passive task - no behavioural measure';
    cfg.InstitutionName =  'University of Rochester';
    cfg.PowerLineFrequency = 60;
    cfg.EEGChannelCount = 64;
    cfg.RecordingType = 'continuous';
    cfg.SamplingFrequency = 512;
    cfg.EEGReference = 'average'; % the average of all channels
    cfg.Manufacturer = 'BioSemi';
    cfg.ManufacturersModelName = 'ActiveTwo';
    
    cfg.coordsystem.EEGCoordinateSystem = 'EEGLAB';
    cfg.coordsystem.EEGCoordinateUnits = 'mm';
    
    cfg.TaskDescription = 'Passive task - no behavioural measure';
    tInfo.InstitutionName =  'University of Rochester';
    tInfo.PowerLineFrequency = 60;
    tInfo.EEGPlacementScheme = '64 channel BioSemi montage';
    tInfo.Manufacturer = 'BioSemi';
    tInfo.ManufacturersModelName = 'ActiveTwo';
    tInfo.HardwareFilters = 'n/a';
    tInfo.SoftwareFilters = 'n/a';
    
    % these are EEG specific
    cfg.eeg.PowerLineFrequency = 60;   % since recorded in the USA
    cfg.eeg.EEGReference       = 'average'; % the average of all channels
    cfg.eeg.SoftwareFilters    = nan;
    
    label_idx = cell(1,64);
    for ichan = 1:64
        label_idx{ichan} = chanlocs_64(ichan).labels;
    end
    
    % all 91 channels in the original recording are of the same type
    cfg.channels.type  = repmat({'EEG'}, channels_cephalic, 1);
    cfg.channels.units = repmat({'uV'}, channels_cephalic, 1);
    %cfg.channels.labels = label_idx';
    cfg.channels.name = label_idx';
    
    % these details should go in the dataset_description.json file
    cfg.dataset_description.Name                = 'Probing basic auditory functioning in Rett Syndrome';
    cfg.dataset_description.Authors             = {'Brima, T.', 'Molholm, S.', 'Beker, S.', 'Prinsloo, K. D.', 'Butler, J. S.', 'Djukic, A.', 'Freeman, E. G.', 'Foxe, J. J.'};
    cfg.dataset_description.KeyWords            = {'RETT', 'Electroencephalography', 'ERP', 'Auditory Evoked Potential','Auditory discrimination','MECP2'};
    cfg.dataset_description.ReferencesAndLinks  = {' '}; % https://www.repository.cam.ac.uk/handle/1810/252736
    cfg.dataset_description.Abstract            = '';
    cfg.dataset_description.Sponsorship         = 'This work was supported by grants from the [] ';
    cfg.dataset_description.License             = 'Attribution 2.0 UK: England & Wales, see http://creativecommons.org/licenses/by/2.0/uk/';
    cfg.dataset_description.BIDSVersion         = '1.2';
        
    % Create BDF datasets
    %------------------------
    data2bids_KP(cfg);
    
    
    % participant column description for participants.json file
    % ---------------------------------------------------------
    pInfoDesc = [];
    pInfoDesc.participant_id.Description = 'unique participant identifier';
    
    pInfoDesc.gender.Description = 'sex of the participant';
    pInfoDesc.gender.Levels.M = 'male';
    pInfoDesc.gender.Levels.F = 'female';
    
    pInfoDesc.age.Description = 'age of the participant';
    pInfoDesc.age.Units       = 'years';
    
    pInfoDesc.group.Description = 'Participant Group Category';
    pInfoDesc.group.Levels.RETT = 'RETT Patient';
    pInfoDesc.group.Levels.Control = 'Control TD';
            
    % P info
    pInfo = pInfo_lst;
    
    % Content for README file
    % -----------------------
    README = sprintf( [ 'Auditory Duration Mismatch Negativity (MMN) experiment\n' ...
        'Subjects consist of Rett Syndrome (RTT) and age-matched typically developing (TD) controls\n' ...
        'article (see Reference) contains all methodological details\n\n' ...
        '> Brima, T.', 'Molholm, S.', 'Beker, S.', 'Prinsloo, K. D.', 'Butler, J. S.', 'Djukic, A.', 'Freeman, E. G.', 'Foxe, J. J.\n\n' ...
        ' ## Trigger value Info\n' ...
        '  3 - 450ms_standard\n' ...
        '  5 - 450ms_deviant\n' ...
        '  7 - 900ms_standard\n' ...
        '  9 - 900ms_deviant\n' ...
        ' 11 - 1800ms_standard\n' ...
        ' 13 - 1800ms_deviant']);
    
    % Content for CHANGES file
    % ------------------------
    CHANGES = sprintf([ 'Revision history for meditation dataset\n\n' ...
        'version 1.0 beta - 17 Oct 2018\n' ...
        ' - Initial release\n' ...
        '\n' ...
        'version 2.0 - 9 Jan 2019\n' ...
        ' - Fixing event field names and various minor issues\n' ...
        '\n' ...
        'Version 3.0 - 20 March 2019\n' ...
        ' - Adding channel location information\n' ]);
    
    % List of script to run the experiment
    code = {''};
    
    % List stim info
    stimuli = {'none','none'};
    
    generalInf = [];
    generalInfo.Name = 'Auditory Duration MMN';
    generalInfo.ReferencesAndLinks = {'Brima, T.', 'Molholm, S.', 'Beker, S.', 'Prinsloo, K. D.', 'Butler, J. S.', 'Djukic, A.', 'Freeman, E. G.', 'Foxe, J. J.'};
    
    % Task redundant information
    % ----------------------------
    
    tInfo.PowerLineFrequency = 60;
    tInfo.ManufacturersModelName = 'ActiveTwo';
    eInfoDesc.onset.Description = 'Event onset';
    eInfoDesc.onset.Units = 'second';
    eInfoDesc.duration.Description = 'Event duration';
    eInfoDesc.duration.Units = 'second';
    
    trialtype = {
        '3','450ms_standard';
        '5','450ms_deviant';
        '7','900ms_standard';
        '9','900ms_deviant';
        '11','1800ms_standard';
        '13','1800ms_deviant';
        };
    
    data( length(file_listings)).file = ([data_path,'\',subject_BIDS_ID{subject_Idx},'\',subject_BIDS_ID{subject_Idx},'-set','\',subject_BIDS_ID{subject_Idx},'.set']);
    data( length(file_listings)).session = [1];
    data( length(file_listings)).run     = [1];
    
    write_participant_json_KP(data,'participant_id',subject_BIDS_ID{subject_Idx},'targetdir', bidsroot, 'taskName','MMN', 'trialtype', trialtype, 'gInfo', generalInfo, 'pInfo', pInfo, 'pInfoDesc', pInfoDesc, 'eInfoDesc', eInfoDesc, 'README', README, 'CHANGES', CHANGES, 'stimuli', stimuli, 'codefiles', code, 'tInfo', tInfo, 'chanlocs', [])
           
end



%------------------------------------------------------
%% Use this if you need to edit Event .jason file
%-----------------------------------------------------

% % add a human-interpretable event table
% hdr = ft_read_header(cfg.dataset);
% nchan = hdr.nChans;
% event = ft_read_event(cfg.dataset);
% nevent = length(event);
% 
% onset     = ([event.sample]' - 1)/512; % starting at t=0
% duration  = zeros(size(onset));
% sample    = [event.sample]'; % starting at sample 1
% type      = {event.type}';
% value     = {event.value}';
% 
% % these are the required columns, i.e. the technical description of the events
% % see https://bids-specification.readthedocs.io/en/stable/04-modality-specific-files/05-task-events.html
% required = table(onset, sample, duration, type, value);
% 
% % these are the required columns, i.e. the technical description of the events
% % see https://bids-specification.readthedocs.io/en/stable/04-modality-specific-files/05-task-events.html
% required = table(onset, sample, duration, type, value);
% 
% % The first digit codes task/no task: 1 for the non-target semantic categories:
% % animals, tools and 2 for the target semantic category: clothing. The subjects’ task
% % was to press the button in response to clothing items, these targets were not
% % analyzed in the main study.
% %
% % The second digit codes the items, 1 to 4 for animals (cow, bear, lion, ape) and 5
% % to 8 for tools (ax, scissors, comb, pen). There were also 4 target items
% % (clothing).
% %
% % The third digit codes the stimulus modality: 1 for written words, 2 for pictures, 3
% % for spoken words.
% 
% task      = cell(nevent,1);  % nontarget, target
% category  = cell(nevent,1);  % animals, tools
% item      = cell(nevent,1);  % cow, bear, lion, ape, ax, scissors, comb, pen
% modality  = cell(nevent,1);  % written, picture, spoken
% 
% for i=1:nevent
%     if strcmp(event(i).type, 'Stimulus')
%         digit1 = str2double(event(i).value(2));
%         digit2 = str2double(event(i).value(3));
%         digit3 = str2double(event(i).value(4));
%         
%         if isnan(digit1) || isnan(digit1) || isnan(digit1)
%             task{i}     = 'unknown';
%             category{i} = 'unknown';
%             item{i}     = 'unknown';
%             modality{i} = 'unknown';
%             continue
%         end
%         
%         switch digit1
%             case 1
%                 task{i} = 'notarget';
%             case 2
%                 task{i} = 'target';
%         end
%         
%         if strcmp(task{i}, 'target')
%             % the interpretation of digit2 is not given for targets
%             category{i} = 'target'; % clothes or vegetables
%             item{i}     = 'target'; % we don't know the actual items
%             
%         else
%             % the following only applies to nontargets
%             switch digit2
%                 case {1, 2, 3, 4}
%                     category{i} = 'animals';
%                 case {5, 6, 7, 8}
%                     category{i} = 'tools';
%             end
%             
%             switch digit2
%                 case 1
%                     item{i} = 'cow';
%                 case 2
%                     item{i} = 'bear';
%                 case 3
%                     item{i} = 'lion';
%                 case 4
%                     item{i} = 'ape';
%                 case 5
%                     item{i} = 'ax';
%                 case 6
%                     item{i} = 'scissors';
%                 case 7
%                     item{i} = 'comb';
%                 case 8
%                     item{i} = 'pen';
%             end
%             
%         end % target or non-target
%         
%         switch digit3
%             case 1
%                 modality{i} = 'written';
%             case 2
%                 modality{i} = 'picture';
%             case 3
%                 modality{i} = 'spoken';
%         end
%         
%     elseif strcmp(event(i).type, 'Response')
%         task{i}     = 'response';
%         category{i} = 'response';
%         item{i}     = 'response';
%         modality{i} = 'response';
%         
%     else
%         task{i}     = 'unknown';
%         category{i} = 'unknown';
%         item{i}     = 'unknown';
%         modality{i} = 'unknown';
%         
%     end % stimulus or response
% end % for
% 
% % these are the interpretation of the events
% interpretation = table(task, category, item, modality);
% 
% % this is for events.tsv, note that it is with an "s"
% cfg.events = cat(2, required, interpretation);
