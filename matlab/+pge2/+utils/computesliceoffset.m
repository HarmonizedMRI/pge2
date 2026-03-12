function slice_offset = computesliceoffset(filename)
% COMPUTESLICEOFFSET  Compute slice offset from isocenter for RF frequency modulation
%
%   slice_offset = computesliceoffset(filename)
%
%   Reads output of `printSHM` (saved to .txt file) and returns the displacement of
%   the prescribed FOV center from isocenter along the slice-select gradient axis.
%   This is the quantity needed to compute the RF frequency offset for
%   oblique/coronal/sagittal slice excitation.
%
%   For axial scans the table moves to place the slice at isocenter, so
%   slice_offset will be near zero, consistent with no RF offset being needed.
%   For oblique/coronal/sagittal scans, the R and A components of the FOV
%   center project onto the (non-axial) slice normal to give a nonzero offset.
%
%   Inputs:
%       filename     - output of `printSHM`, `printSHM > filename`, containing
%                      _groupCenter.r/a/s and _groupNormal_N.r/a/s fields
%
%   Outputs:
%       slice_offset - displacement from isocenter along slice-select
%                      gradient direction, in mm
%
%   Notes:
%     - The S/I component of _groupCenter is zeroed out because the scanner
%       table moves to handle S/I positioning; _optloc in EPIC already
%       reflects the post-table-move residual offset.
%     - _groupNormal_N is sign-corrected to point superior (GE convention),
%       so slice_offset is positive for slices superior to isocenter.
%
%   Jon Nielsen 2026

txt = readlines(filename);
txt = strtrim(txt);
getVal = @(var) sscanf(txt{contains(txt, var)}, '%*s = %f');

% FOV center in scanner RAS frame; zero S/I (table handles that)
c = [ getVal('_groupCenter.r'); getVal('_groupCenter.a'); 0 ];

% Slice-select normal in scanner frame
Z = [ getVal('_groupNormal_N.r'); getVal('_groupNormal_N.a'); getVal('_groupNormal_N.s') ];

% Enforce GE convention: slice normal points superior (+S)
if Z(3) < 0
    Z = -Z;
end

% Distance from isocenter along slice-select direction (mm)
slice_offset = dot(Z, c);

