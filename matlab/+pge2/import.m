function psg = import(input, varargin)
% IMPORT Import supported representations into a pge2 psg struct.
%
% Syntax:
%   psg = pge2.import(pulseg_ir)
%   psg = pge2.import(seqfile)

    if isstruct(input) && isfield(input, 'pulseg_version')
        psg = pge2.pulseg2psg(input, varargin{:});
        return;
    end

    if ischar(input) || isstring(input)
        pulseg_ir = pulseg.import(char(input));
        psg = pge2.pulseg2psg(pulseg_ir, varargin{:});
        return;
    end

    error('pge2.import:UnsupportedInput', ...
        'Unsupported input type for pge2.import.');
end
