function pge_ir = import(input, varargin)
% IMPORT Import supported representations into a pge2 pge_ir struct.
%
% Syntax:
%   pge_ir = pge2.import(pulseg_ir)
%   pge_ir = pge2.import(seqfile)

    if isstruct(input) && isfield(input, 'pulseg_version')
        pge_ir = pge2.pulseg2pge(input, varargin{:});
        return;
    end

    if ischar(input) || isstring(input)
        pulseg_ir = pulseg.import(char(input));
        pge_ir = pge2.pulseg2pge(pulseg_ir, varargin{:});
        return;
    end

    error('pge2.import:UnsupportedInput', ...
        'Unsupported input type for pge2.import.');
end
