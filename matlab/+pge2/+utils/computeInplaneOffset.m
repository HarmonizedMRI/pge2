function [x_offset,y_offset] = computeInplaneOffset(filename)
% COMPUTEINPLANEOFFSET  Compute in-plane offset from isocenter for RF frequency modulation
%
%   [x_offset,y_offset] = computeInplaneOffset(filename)
%
%   Reads output of `printSHM` (saved to .txt file) and returns the displacement of
%   the prescribed FOV center from isocenter along the readout(x_offset) and phase-ecode(y_offset) axes.

%
%   Inputs:
%       filename     - .txt file; output of `printSHM`, `printSHM > filename`, containing
%                      _groupCenter.r/a/s and 
%                      _groupNormal1.r/a/s _groupNormal2.r/a/s _groupNormal_N.r/a/s fields and
%                      _frequencyDir
%
%   Outputs:
%       x_offset - displacement from isocenter along readout gradient direction, in mm
%       y_offset - displacement from isocenter along phase gradient direction, in mm
%
%   Notes:
%     - This script is only validated for axial scans; for
%     oblique/coronal/sagittal scans, need more info from GE
%
%   Yongli He 2026

txt = readlines(filename);
txt = strtrim(txt);
getVal = @(var) sscanf(txt{contains(txt, var)}, '%*s = %f');

% FOV center in scanner RAS frame; zero S/I (table handles that)
c = [ getVal('_groupCenter.r'); getVal('_groupCenter.a'); 0 ];

% logical axes normal1 in scanner frame
e1 = [ getVal('_groupNormal1.r'); getVal('_groupNormal1.a'); getVal('_groupNormal1.s') ];
e2 = [ getVal('_groupNormal2.r'); getVal('_groupNormal2.a'); getVal('_groupNormal2.s') ];

% Readout direction in scanner frame
freqLine = txt{find(contains(txt, '_frequencyDir'), 1)};
freqDir  = sscanf(freqLine, '%*s = (%f,%f,%f)');   % returns, for example, [1.0; 0.0; 0.0]


if abs(dot(e1,freqDir))>=abs(dot(e2,freqDir))
    % freqDir aligns with e1
    X = e1;
    Y = e2;
else
    % freqDir aligns with e2
    X = e2;
    Y = e1;
end

% Distance from isocenter along slice-select direction (mm)
[x_offset,y_offset] = deal(dot(X, c),dot(Y,c));