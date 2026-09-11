function compilePGE_cli(seqFile, opuser1, outputFile, configFile, noTranslateFOV)

% compilePGE_cli Command-line wrapper for compilePGE.
%
% Intended for use with MATLAB Compiler:
%
%   mcc -m compilePGE_cli.m
%
% Usage through the generated runtime launcher:
%
%   compilePGE_cli seqFile opuser1 outputFile configFile [noTranslateFOV]

arguments
    seqFile
    opuser1
    outputFile
    configFile
    noTranslateFOV = 'false'
end

opuser1 = str2double(opuser1);
if isnan(opuser1)
    error('compilePGE_cli:InvalidOpuser1', ...
        'opuser1 must be numeric.');
end

opts = loadOptionsJSON(configFile);

noTranslateFOV = strcmpi(string(noTranslateFOV), 'true');

if noTranslateFOV && isfield(opts, 'translateFOV')
    opts = rmfield(opts, 'translateFOV');
end

compilePGE(seqFile, opuser1, outputFile, opts);

