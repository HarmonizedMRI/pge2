function translateFOVrf(mat_file, Rxfile, opuser1, output_file)
% translateFOVrf -- Apply FOV translation to a PulSeg 2.x intermediate representation,
% and output the resulting sequence to a .pge file for execution on GE.
%
% function translateFOVrf(mat_file, Rxfile, opuser1, output_file)
%
% Loads 'mat_file' and a FOV scan prescription info file, applies FOV translation
% to all RF pulses (insde base blocks), and writes the resulting sequence to
% output_file. At the moment, only applies a z-shift.
% Also writes a corresponding .entry file.
%
% Inputs
%   mat_file     string   .mat file containing PulSeg intermediate representation (pulseg_ir)
%                         and associated GE-specific parameters (params, pislquant)
%   Rxfile       string   Text file containing output of `printSHM`, e.g., `printSHM > Rx.txt`
%   opuser1      int      Determines pge<opuser1>.entry file name
%   output_file  string   .pge output file name

% Read z offset
z_offset = pge2.utils.computesliceoffset(Rxfile);   % mm
fprintf('z_offset = %.2f mm\n', z_offset);

% Load PulSeg struct
[~, seq_name, ~] = fileparts(mat_file);    % Remove file extension if present
mat_file = strcat(seq_name, '.mat');
if ~isfile(mat_file)
    error('translateFOVrf: file not found: %s', mat_file);
end

S = load(mat_file);

requiredFields = {'pulseg_ir', 'params', 'pislquant'};
missing = requiredFields(~isfield(S, requiredFields));
if ~isempty(missing)
    error('Missing required field(s) in %s: %s', ...
        mat_file, strjoin(missing, ', '));
end

% Apply FOV translation
try
    pulseg_ir = pulseg.translateFOVrf(S.pulseg_ir, [0 0 z_offset*1e-3]);
catch ME
    warning('pulseg.translateFOVrf failed -- this may happen for block pulses, which is typically ok.\n  Message: %s', ME.message);
end

% Write .pge and .entry files
pge = pge2.import(pulseg_ir, 'grad_raster_time', 4e-6);
pge2.serialize(pge, output_file, 'pislquant', S.pislquant, 'params', S.params, 'checkHash', false);
pge2.writeentryfile(opuser1, output_file, 'path', pwd);
