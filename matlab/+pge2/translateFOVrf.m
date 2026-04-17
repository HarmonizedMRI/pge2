function psq = translateFOVrf(psq, offset)
% translateFOVrf - Apply RF frequency modulation according to desired FOV offset/translation
%
% function psq = translateFOVrf(psq, offset)
%
% Adds frequency modulation to the base blocks of a PulSeq sequence, according to 'offset'.
% This assumes that the gradient amplitude doesn't change across base block instances.
% This function also assumes that any RF pulse containing gradients are arbitrary
% (uniformly sampled) waveforms -- block pulses are ignored.
%
% Inputs
%   psq        struct       PulSeg sequence object, see pulseg.fromSeq()
%   offset     [3]          shift in logical x, y, z coordinates (m)
%
% Ouput
%   psq     struct       Same as input, except with added frequency modulation

% Fail-safe: default is no-op
if nargin < 2 || isempty(offset) || all(offset == 0)
    return;
end

% Basic sanity
if ~isfield(psq, 'parentBlocks') || isempty(psq.parentBlocks)
    return;
end

for ib = 1:numel(psq.parentBlocks)

    try
        % --- Check RF exists ---
        if ~isfield(psq.parentBlocks(ib), 'block')
            continue;
        end
        b = psq.parentBlocks(ib).block;

        if ~isfield(b, 'rf') || isempty(b.rf) 
            continue;
        end

        % --- Build temporary sequence ---
        seq = mr.Sequence();
        seq.addBlock(b.rf, b.gx, b.gy, b.gz);

        w = seq.waveforms_and_times(true);

        % --- Validate waveform structure ---
        if numel(w) < 4 || isempty(w{4}) || size(w{4},1) < 2
            continue;
        end

        % Extract RF waveform
        t_rf = w{4}(1,2:end-1);
        sig_rf = w{4}(2,2:end-1);

        if isempty(t_rf) || isempty(sig_rf)
            continue;
        end

        % Length consistency check
        if length(sig_rf) ~= length(b.rf.signal)
            continue;
        end

        % --- Compute frequency shift ---
        f = zeros(size(t_rf));

        for d = 1:min(numel(offset), 3)
            if numel(w) < d || isempty(w{d}) || size(w{d},1) < 2
                continue;
            end

            % Safe interpolation (NO extrapolation)
            g = interp1(w{d}(1,:), w{d}(2,:), t_rf, 'linear', 'extrap');

            if any(isnan(g))
                continue;
            end

            f = f + g * offset(d);
        end

        % --- Integrate to phase ---
        dt = diff(t_rf);
        if isempty(dt)
            continue;
        end

        dt = [dt dt(end)]; % match length

        th = 2*pi * cumsum(f .* dt);

        if any(isnan(th)) || ~isvector(th)
            continue;
        end

        % --- RF center phase ---
        if ~isfield(b.rf, 'delay') || ~isfield(b.rf, 'center')
            continue;
        end

        t_center = b.rf.delay + b.rf.center;

        th_center = interp1(t_rf, th, t_center, 'linear', NaN);

        if isnan(th_center)
            continue;
        end

        % --- Final safety check ---
        if length(th) ~= length(b.rf.signal)
            continue;
        end

        % --- Apply phase modulation (SAFE WRITE) ---
        new_signal = b.rf.signal .* exp(1i * (th(:) - th_center));

        if any(isnan(new_signal))
            continue;
        end

        % Commit only after everything passes
        psq.parentBlocks(ib).block.rf.signal = new_signal;

    catch
        % Absolute fail-safe: do nothing for this block
        continue;
    end

end
