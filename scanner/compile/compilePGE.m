function compilePGE(seqFile, opuser1, pislquant, outputFile, opts, options)

% compilePGE Convert a Pulseq .seq file to a GE .pge file.
%
% compilePGE(seqFile, opuser1, pislquant, outputFile, opts)
% compilePGE(..., 'soft_delay_input_ms', value)

arguments
    seqFile
    opuser1
    pislquant
    outputFile
    opts struct
    options.soft_delay_input_ms = []
end

% Sequence-specific values must not also be defined in the shared config.
if isfield(opts, 'pulseg_import') && ...
        isfield(opts.pulseg_import, 'soft_delay_input_ms')
    error('compilePGE:SoftDelayInputInOptions', ...
        ['soft_delay_input_ms is sequence-specific and must be passed ' ...
         'directly to compilePGE(), not defined in opts.pulseg_import.']);
end

if isfield(opts, 'pge_serialize') && isfield(opts.pge_serialize, 'pislquant')
    error('compilePGE:PislquantInOptions', ...
        ['pislquant is sequence-specific and must be passed directly ' ...
         'to compilePGE(), not defined in opts.pge_serialize.']);
end

args = getNamedArgs(opts, 'pulseg_import');
if ~isempty(options.soft_delay_input_ms)
    args = [args, {'soft_delay_input_ms', options.soft_delay_input_ms}];
end
pulseg_ir = pulseg.import(seqFile, args{:});

if isfield(opts, 'translateFOV')
    if ~isfield(opts.translateFOV, 'Rxfile')
        error('compilePGE:MissingRxfile', ...
            'opts.translateFOV.Rxfile must be specified.');
    end
    Rxfile = opts.translateFOV.Rxfile;
    if ~isfile(Rxfile)
        error('compilePGE:RxfileNotFound', ...
            'Prescription file not found: %s', Rxfile);
    end
    z_offset = pge2.utils.computesliceoffset(Rxfile); % mm
    fprintf('z_offset = %.2f mm\n', z_offset);
    try
        pulseg_ir = pulseg.translateFOVrf( ...
            pulseg_ir, [0 0 z_offset * 1e-3]);
    catch ME
        warning('compilePGE:TranslateFOVFailed', ...
            ['pulseg.translateFOVrf failed. This may happen for ' ...
             'block pulses, which is typically okay.\nMessage: %s'], ...
            ME.message);
    end
end

args = getNamedArgs(opts, 'pge_import');
pge = pge2.import(pulseg_ir, args{:});

if ~isfield(opts, 'sys_ge')
    error('compilePGE:MissingSystemOptions', ...
        'opts.sys_ge must be specified.');
end

args = getNamedArgs(opts, 'pge_check');
params = pge2.check(pge, opts.sys_ge, args{:});

args = getNamedArgs(opts, 'pge_serialize');
pge2.serialize( ...
    pge, outputFile, ...
    'params', params, ...
    'pislquant', pislquant, ...
    args{:});

args = getNamedArgs(opts, 'pge_writeentryfile');
pge2.writeentryfile(opuser1, outputFile, args{:});

return

function args = getNamedArgs(opts, fieldName)
if isfield(opts, fieldName)
    if ~isstruct(opts.(fieldName))
        error('compilePGE:InvalidOptionGroup', ...
            'opts.%s must be a structure.', fieldName);
    end
    args = namedargs2cell(opts.(fieldName));
else
    args = {};
end
