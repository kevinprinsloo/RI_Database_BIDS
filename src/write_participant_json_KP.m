

function write_participant_json_KP(files,varargin)

%participants = { 'participant_id' };

opt = finputcheck(varargin,{
    'participant_id' 'string' {} '';
    'Name'      'string'  {}    '';
    'License'   'string'  {}    '';
    'Authors'   'cell'    {}    {''};
    'ReferencesAndLinks' 'cell' {}    {''};
    'targetdir' 'string'  {}    fullfile(pwd, 'bidsexport');
    'taskName'  'string'  {}    'Experiment';
    'codefiles' 'cell'    {}    {};
    'stimuli'   'cell'    {}    {};
    'pInfo'     'cell'    {}    {};
    'eInfo'     'cell'    {}    {};
    'cInfo'     'cell'    {}    {};
    'gInfo'     'struct'  {}    struct([]);
    'tInfo'     'struct'  {}    struct([]);
    'pInfoDesc' 'struct'  {}    struct([]);
    'eInfoDesc' 'struct'  {}    struct([]);
    'cInfoDesc' 'struct'  {}    struct([]);
    'trialtype' 'cell'    {}    {};
    'renametype' 'cell'   {}    {};
    'checkresponse' 'string'   {}    '';
    'anattype'  ''        {}    'T1w';
    'chanlocs'  ''        {}    '';
    'chanlookup' 'string' {}    '';
    'interactive' 'string'  {'on' 'off'}    'off';
    'defaced'   'string'  {'on' 'off'}    'on';
    'createids' 'string'  {'on' 'off'}    'off';
    'noevents'  'string'  {'on' 'off'}    'off';
    'individualEventsJson' 'string'  {'on' 'off'}    'off';
    'exportext' 'string'  { 'edf' 'eeglab' } 'eeglab';
    'README'    'string'  {}    '';
    'CHANGES'   'string'  {}    '' ;
    'copydata'   'real'   [0 1] 1 }, 'bids_export');

% write participants field description (participants.json)
% --------------------------------------------------------

% Write README files (README)
% ---------------------------
if ~isempty(opt.README)
    if exist(opt.README) ~= 2
        fid = fopen(fullfile(opt.targetdir, 'README'), 'w');
        if fid == -1, error('Cannot write README file'); end
        fprintf(fid, '%s', opt.README);
        fclose(fid);
    else
        copyfile(opt.README, fullfile(opt.targetdir, 'README'));
    end
end

% Write CHANGES files (CHANGES)
% -----------------------------
if ~isempty(opt.CHANGES)
    if ~exist(opt.CHANGES)
        fid = fopen(fullfile(opt.targetdir, 'CHANGES'), 'w');
        if fid == -1, error('Cannot write README file'); end
        fprintf(fid, '%s', opt.CHANGES);
        fclose(fid);
    else
        copyfile(opt.CHANGES, fullfile(opt.targetdir, 'CHANGES'));
    end
end

% Write code files (code)
% -----------------------
if ~isempty(opt.codefiles)
    for iFile = 1:length(opt.codefiles)
        [~,fileName,Ext] = fileparts(opt.codefiles{iFile});
        if ~isempty(dir(opt.codefiles{iFile}))
            copyfile(opt.codefiles{iFile}, fullfile(opt.targetdir, 'code', [ fileName Ext ]));
        else
            fprintf('Warning: cannot find code file %s\n', opt.codefiles{iFile})
        end
    end
end

% Write stimulus files
% --------------------
if ~isempty(opt.stimuli)
    disp('Copying stimuli...');
    for iStim = 1:size(opt.stimuli,1)
        [~,fileName,Ext] = fileparts(opt.stimuli{iStim,2});
        if ~isempty(dir(opt.stimuli{iStim,2}))
            copyfile(opt.stimuli{iStim,2}, fullfile(opt.targetdir, 'stimuli', [ fileName Ext ]));
        else
            fprintf('Warning: cannot find stimulus file %s\n', opt.stimuli{iStim,2});
        end
        opt.stimuli{iStim,2} = [ fileName,Ext ];
    end
end


% make cell out of file names if necessary
% ----------------------------------------
for iSubj = 1:length(files)
    if ~iscell(files(iSubj).file)
        if isstruct(files(iSubj).file)
            if isfield(files(iSubj).file, 'session')
                files(iSubj).session  = [ files(iSubj).file.session  ];
            end
            if isfield(files(iSubj).file, 'run')
                files(iSubj).run      = [ files(iSubj).file.run  ];
            end
            if isfield(files(iSubj).file, 'task')
                files(iSubj).task      = { files(iSubj).file.task  };
            end
            if isfield(files(iSubj).file, 'instructions')
                files(iSubj).task      = { files(iSubj).file.instructions };
            end
            files(iSubj).file     = { files(iSubj).file.file };
        else
            files(iSubj).file = { files(iSubj).file };
        end
    end
    
    % write participant information (participants.tsv)
    % -----------------------------------------------
    if ~isempty(opt.pInfo)
        if isfield(files, 'subject')
            uniqueSubject = unique( { files.subject } );
            if size(opt.pInfo,1)-1 ~= length( uniqueSubject )
                error(sprintf('Wrong number of participant (%d) in pInfo structure, should be %d based on the number of files', size(opt.pInfo,1)-1, length( uniqueSubject )));
            end
        elseif ~isstruct(files(1).file)
            if size(opt.pInfo,1)-1 ~= length( files )
                error(sprintf('Wrong number of participant (%d) in pInfo structure, should be %d based on the number of files', size(opt.pInfo,1)-1, length( files )));
            end
        end
        participants = { 'participant_id' };
        for iSubj=2:size(opt.pInfo)
            if strcmp('participant_id', opt.pInfo{1,1})
                if length(opt.pInfo{iSubj,1}) > 3 && isequal('sub-', opt.pInfo{iSubj,1}(1:4))
                    participants{iSubj, 1} = opt.pInfo{iSubj,1};
                elseif strcmpi(opt.createids, 'off')
                    participants{iSubj, 1} = sprintf('sub-%s', opt.pInfo{iSubj,1});
                else
                    participants{iSubj, 1} = sprintf('sub-%3.3d', iSubj-1);
                end
            else
                participants{iSubj, 1} = sprintf('sub-%3.3d', iSubj-1);
            end
        end
        if size(opt.pInfo,2) > 1
            if strcmp('participant_id', opt.pInfo{1,1})
                participants(:,2:size(opt.pInfo,2)) = opt.pInfo(:,2:end);
            else
                participants(:,2:size(opt.pInfo,2)+1) = opt.pInfo;
            end
        end
        
        writetsv(fullfile(opt.targetdir, 'participants.tsv'), participants);
    end
    
    
    descFields = { 'LongName'     'optional' 'char'   '';
        'Levels'       'optional' 'struct' struct([]);
        'Description'  'optional' 'char'   '';
        'Units'        'optional' 'char'   '';
        'TermURL'      'optional' 'char'   '' };
    if ~isempty(opt.pInfo)
        fields = fieldnames(opt.pInfoDesc);
        if ~isempty(setdiff(fields, participants(1,:)))
            error('Some field names in the pInfoDec structure do not have a corresponding column name in pInfo');
        end
        fields = participants(1,:);
%         for iField = 1:length(fields)
%             descFields{1,4} = fields{iField};
%             if ~isfield(opt.pInfoDesc, fields{iField}), opt.pInfoDesc(1).(fields{iField}) = struct([]); end
%             opt.pInfoDesc.(fields{iField}) = checkfields(opt.pInfoDesc.(fields{iField}), descFields, 'pInfoDesc');
%         end
        jsonwrite(fullfile(opt.targetdir, 'participants.json'), opt.pInfoDesc,struct('indent','  '));
    end
end

% write TSV file
% --------------
    function writetsv(fileName, matlabArray)
        fid = fopen(fileName, 'w', 'n', 'UTF-8');
        if fid == -1, error('Cannot write file - make sure you have writing permission'); end
        for iRow=1:size(matlabArray,1)
            for iCol=1:size(matlabArray,2)
                if isempty(matlabArray{iRow,iCol})
                    %disp('Empty value detected, replacing by n/a');
                    fprintf(fid, 'n/a');
                elseif ischar(matlabArray{iRow,iCol})
                    fprintf(fid, '%s', matlabArray{iRow,iCol});
                elseif isnumeric(matlabArray{iRow,iCol}) && rem(matlabArray{iRow,iCol},1) == 0
                    fprintf(fid, '%d', matlabArray{iRow,iCol});
                elseif isnumeric(matlabArray{iRow,iCol})
                    fprintf(fid, '%1.10f', matlabArray{iRow,iCol});
                else
                    error('Table values can only be string or numerical values');
                end
                if iCol ~= size(matlabArray,2)
                    fprintf(fid, '\t');
                end
            end
            fprintf(fid, '\n');
        end
        fclose(fid);
        
    end

% check the fields for the structures
% -----------------------------------
function s = checkfields(s, f, structName)

fields = fieldnames(s);
diffFields = setdiff(fields, f(:,1)');
if ~isempty(diffFields)
    fprintf('Warning: Ignoring invalid field name(s) "%s" for structure %s\n', sprintf('%s ',diffFields{:}), structName);
    s = rmfield(s, diffFields);
end
for iRow = 1:size(f,1)
    if isempty(s) || ~isfield(s, f{iRow,1})
        if strcmpi(f{iRow,2}, 'required') % required or optional
            if ~iscell(f{iRow,4})
                fprintf('Warning: "%s" set to %s\n', f{iRow,1}, num2str(f{iRow,4}));
            end
            s = setfield(s, {1}, f{iRow,1}, f{iRow,4});
        end
    elseif ~isempty(f{iRow,3}) && ~isa(s.(f{iRow,1}), f{iRow,3}) && ~strcmpi(s.(f{iRow,1}), 'n/a')
        % if it's HED in eInfoDesc, allow string also
        if strcmp(structName,'eInfoDesc') && strcmp(f{iRow,1}, 'HED') && isa(s.(f{iRow,1}), 'char')
            return
        end
        error(sprintf('Parameter %s.%s must be a %s', structName, f{iRow,1}, f{iRow,3}));
    end
end

end
end










