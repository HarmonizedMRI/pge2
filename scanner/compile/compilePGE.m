function compilePGE(seqFile, opuser1, outputFile, opts)
% compilePGE  Convert a Pulseq .seq file to a GE .pge file.
%
% compilePGE(seqFile, opuser1, outputFile, opts)
%
% The opts structure may contain:
%   opts.pulseg_import   options passed to pulseg.import()
%   opts.translateFOV    scanner FOV prescription settings
%   opts.pge_import      options passed to pge2.import()
%   opts.sys_ge          GE scanner settings. Output of pge2.opts().
%   opts.pge_check       options passed to pge2.check()
%   opts.pge_serialize   options passed to pge2.serialize()

arguments
    seqFile
    opuser1
    outputFile
    opts struct
end

% Import Pulseq sequence into PulSeg IR
args = getNamedArgs(opts, 'pulseg_import');
pulseg_ir = pulseg.import(seqFile, args{:});

% Optionally apply FOV translation
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

    z_offset = pge2.utils.computesliceoffset(Rxfile);   % mm
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

% Convert PulSeg IR to PGE
args = getNamedArgs(opts, 'pge_import');
pge = pge2.import(pulseg_ir, args{:});

% Check timing, PNS, and hardware limits
if ~isfield(opts, 'sys_ge')
    error('compilePGE:MissingSystemOptions', ...
        'opts.sys_ge must be specified.');
end

args = getNamedArgs(opts, 'pge_check');
params = pge2.check(pge, opts.sys_ge, args{:});

% Serialize to GE binary format
args = getNamedArgs(opts, 'pge_serialize');
pge2.serialize( ...
    pge, outputFile, ...
    'params', params, ...
    args{:});

% Write the corresponding entry file
args = getNamedArgs(opts, 'pge_writeentryfile');
pge2.writeentryfile(opuser1, outputFile, args{:});

return


function args = getNamedArgs(opts, fieldName)
% Return a structure field as MATLAB name-value arguments.

if isfield(opts, fieldName)
    if ~isstruct(opts.(fieldName))
        error('compilePGE:InvalidOptionGroup', ...
            'opts.%s must be a structure.', fieldName);
    end

    args = namedargs2cell(opts.(fieldName));
else
    args = {};
end

