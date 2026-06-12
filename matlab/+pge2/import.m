function pge = import(input, varargin)
% IMPORT Import supported representations into a pge2 pge struct.
%
% Syntax:
%   pge = pge2.import(pulseg_ir)
%   pge = pge2.import(seqfile)

    if isstruct(input) && isfield(input, 'pulseg_version')
        pge = pge2.pulseg2pge(input, varargin{:});
        return;
    end

    if ischar(input) || isstring(input)
        pulseg_ir = pulseg.import(char(input));
        pge = pge2.pulseg2pge(pulseg_ir, varargin{:});
        return;
    end

    error('pge2.import:UnsupportedInput', ...
        'Unsupported input type for pge2.import.');
end
