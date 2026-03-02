function psq = translateFOVrf(psq, offset)
% translateFOVrf - Apply RF frequency modulation according to desired FOV offset/translation
%
% function psq = translateFOVrf(psq, offset)
%
% Adds frequency modulation to the base blocks of a PulSeq sequence, according to 'offset'.
% This assumes that the gradient amplitude doesn't change across base block instances.
% This function also assumes that any RF pulse containing gradients are arbitrary
% (uniformly sampled) waveforms.
%
% Inputs
%   psq        struct       PulSeg sequence object, see pulseg.fromSeq()
%   offset     [3]          shift in logical x, y, z coordinates (m)
%
% Ouput
%   psq     struct       Same as input, except with added frequency modulation

% Loop over base blocks
for ib = 1 : psq.nParentBlocks

    b = psq.parentBlocks(ib).block;  % base block

    if ~isempty(b.rf) 
        % Get rf waveform and times
        seq = mr.Sequence();  
        seq.addBlock(b.rf, b.gx, b.gy, b.gz);
        w = seq.waveforms_and_times(true);
        rf.t = w{4}(1,2:end-1);   % NB! time reference is start of block
        rf.signal = w{4}(2,2:end-1);

        % Calculate frequency modulation waveform corresponding to requested offset
        % See Magland et al Magn Reson Med 56 (2006) 230-233.
        f = zeros(size(rf.t));   % Hz
        for d = 1:3               % loop over gradient axes
            if length(w{d}) > 0
                g = interp1(w{d}(1,:), w{d}(2,:), rf.t);  % gradient waveform, Hz/m
                f = f + g*offset(d);
            end
        end

        % Calculate corresponding phase modulation
        th = unwrap(angle(exp(1i*2*pi*f.*rf.t)));
        th_center = interp1(rf.t, th, b.rf.delay + b.rf.center);

        % Add phase modulation to RF pulse
        psq.parentBlocks(ib).block.rf.signal = b.rf.signal .* exp(1i*(th(:) - th_center));

        % visually check that RF phase at center is unchanged:
        %b2 = b;
        %b2.rf.signal = b2.rf.signal .* exp(1i*(th(:)-th_center));
        %seq = mr.Sequence();  
        %seq.addBlock(b2.rf);
        %seq.plot();
    end
end


