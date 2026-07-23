function opts = loadOptionsJSON(optsFile)

optsFile = string(optsFile);

if ~isfile(optsFile)
    error('compilePGE:OptionsFileNotFound', ...
        'Options file not found: %s', optsFile);
end

try
    opts = jsondecode(fileread(optsFile));
catch ME
    error('compilePGE:InvalidOptionsJSON', ...
        'Could not read JSON options file "%s": %s', ...
        optsFile, ME.message);
end

if ~isstruct(opts) || ~isscalar(opts)
    error('compilePGE:InvalidOptionsJSON', ...
        'The JSON root must contain one object.');
end

opts = createSysGE(opts);

if isfield(opts, 'pge_check') && ...
        isfield(opts.pge_check, 'pns_weights')

    opts.pge_check.PNSwt = opts.pge_check.pns_weights;
    opts.pge_check = rmfield(opts.pge_check, 'pns_weights');
end



function opts = createSysGE(opts)

if ~isfield(opts, 'pge_opts')
    error('compilePGE:MissingPGEOptions', ...
        'The JSON file must contain a "pge_opts" object.');
end

p = opts.pge_opts;

requiredFields = { ...
    'psd_rf_wait', ...
    'psd_grd_wait', ...
    'b1_max', ...
    'g_max', ...
    'slew_max', ...
    'coil'};

missingFields = requiredFields(~isfield(p, requiredFields));

if ~isempty(missingFields)
    error('compilePGE:MissingPGEOptions', ...
        'Missing required pge_opts field(s): %s', ...
        strjoin(missingFields, ', '));
end

optionArgs = {};

if isfield(p, 'options')
    if ~isstruct(p.options) || ~isscalar(p.options)
        error('compilePGE:InvalidPGEOptions', ...
            '"pge_opts.options" must be a JSON object.');
    end

    optionArgs = namedargs2cell(p.options);
end

opts.sys_ge = pge2.opts( ...
    p.psd_rf_wait, ...
    p.psd_grd_wait, ...
    p.b1_max, ...
    p.g_max, ...
    p.slew_max, ...
    p.coil, ...
    optionArgs{:});

opts = rmfield(opts, 'pge_opts');

