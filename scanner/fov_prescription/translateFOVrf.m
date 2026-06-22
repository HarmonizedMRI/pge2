function translateFOVrf(seq_name, Rxfile, opuser1, output_file)
% translateFOVrf -- Apply FOV translation to a Pulseq/PGE sequence object
%
% function translateFOVrf(seq_name, Rxfile, opuser1, output_file)
%
% Loads 'seq_name.mat' and a FOV scan prescription info file, applies FOV translation
% to all RF pulses (insde base blocks), and writes the resulting sequence to
% output_file. At the moment, only applies a z-shift.
% Also writes a corresponding .entry file.
%
% Inputs
%   seq_name     string   .mat file containing Pulseq/PGE sequence (pge, params, pislquant)
%   Rxfile       string   Text file containing output of `printSHM`, e.g., `printSHM > Rx.txt`
%   opuser1      int      Determines pge<opuser1>.entry file name
%   output_file  string   .pge output file name

% Remove file extension if present
[~, seq_name, ~] = fileparts(seq_name);

% Read z offset
z_offset = pge2.utils.computesliceoffset(Rxfile);   % mm
fprintf('z_offset = %.2f mm\n', z_offset);

% Load Pulseq/PGE sequence
mat_file = strcat(seq_name, '.mat');
if ~isfile(mat_file)
    error('translateFOVrf: file not found: %s', mat_file);
end

S = load(filename);

if isfield(S, 'pge')
    pge = S.pge;
elseif isfield(S, 'psq')
    pge = S.psq;   % alias psq -> pge
else
    error('Expected variable "pge" or "psq" in %s.', filename);
end

% Apply FOV translation
try
    pge = pge2.translateFOVrf(pge, [0 0 z_offset*1e-3]);
catch ME
    warning('translateFOVrf: pge2.translateFOVrf failed -- this may happen for block pulses, which is typically ok.\n  Message: %s', ME.message);
end

% Write .pge and .entry files
pge2.serialize(pge, output_file, 'pislquant', pislquant, 'params', params, 'checkHash', false);
pge2.writeentryfile(opuser1, output_file, 'path', pwd);
