function translateFOVrf(seq_name, Rxfile, opuser1, output_file)
% translateFOVrf -- Apply FOV translation to a PulSeg sequence object
% 
% function translateFOVrf(seq_name, Rxfile, opuser1, output_file)
% 
% Loads 'seq_name.mat' and 'Rx.txt', applies FOV translation to all RF pulses (base blocks),
% and writes the resulting sequence to the `seq_name.pge`.
% At the moment, only applies z shift.
%
% Inputs
%   seq_name          string     .mat file name containing PulSeg sequence (psq, params, pislquant)
%   Rxfile   string     Text file containing output of `printSHM`, e.g., `printSHM > Rx.txt`
%   opuser1           int        Determines pge<opuser1>.entry file name
%   output_file       string     .pge output file name

% remove file name extension if present
seq_name = erase(seq_name, {'.bin', '.pge2', '.pge', '.seq', '.mat'});

% read z offset
z_offset = pge2.utils.computesliceoffset(Rxfile);   % cm

% load PulSeg sequence and apply offset
try
    load(seq_name + '.mat')  % psq, params, pislquant
catch ME
    error(ME.message);
end
pge2.translateFOVrf(psq, [0 0 z_offset*1e-2]);

% write .pge file and corresponding .entry file
pge2.serialize(psq, output_file, 'pislquant', pislquant, 'params', params);
pge2.writeentryfile(opuser1, output_file);

