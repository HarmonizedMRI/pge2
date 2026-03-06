function ok = validate(psq, sys_ge, seq, xmlPath, varargin)
% validate - Compare waveforms in PulSeg object/WTools against original .seq file
% 
% function validate(psq, sys_ge, seq, xmlPath, ...)
%
% Check agreement between pge2 interpreter output on scanner/VM/WTools
% and the original Pulseq (.seq) object.
% If 'xmlPath' is empty ([]), the psq object is used instead.
%
% Inputs:
%   psq       struct         PulSeg sequence object, see pulseg.fromSeq()
%   sys_ge     struct         System hardware info, see pge2.opts()
%   seq       struct         A Pulseq sequence object
%   xmlPath   string or []   Path to folder containing scan.xml.<xxxx> files.
%                            These files are also used by GE's Pulse View sequence plotter.
%                            If empty, the psq object is used instead.
% 
% Input options:
%   'row'           [1] or 'all'/[]   Check and plot segment starting at this number in .seq file (default: 'all')
%                                     If row is not on a segment boundary, the following segment will be plotted.
%   'plot'          true/FALSE        Plot each segment (continue to next on pressing 'Enter')
%   'threshRFper'   [1]               RF error tolerance (percent rms error). Default: 1.
%   'b1PlotLim'     [1]               RF plot limit (Gauss). Default: sys_ge.b1_max 

% Default options
% Re: thresRFper: Some interpolation error is ok; 
% the main failure modes we're after are things like conj/sign change, and gross timing offsets
arg.row = 'all';      
arg.plot = false;   
arg.threshRFper = 1;  
arg.b1PlotLim = sys_ge.b1_max;  % Gauss

arg = vararg_pair(arg, varargin);   % in ../

doNextSegment = true;
if ischar(arg.row) | isempty(arg.row)
    arg.row = 1;
end

if ~isempty(xmlPath)
    xmlPath = ensuretrailingslash(xmlPath);
end

axesLinked = false;

ok = true;

% Loop over segments
teps = 1e-12;
cnt = 0;   % segment instance counter
n = 1;
if ~arg.plot
    textprogressbar('pge2.validate(): Checking scan loop: ');
else
    figure
end
while n < psq.nMax % & cnt < 2
    cnt = cnt + 1;

    % determine block range
    i = psq.loop(n,1);        % segment index
    n1 = n;
    n2 = n - 1 + psq.segments(i).nBlocksInSegment;

    if n < arg.row
        n = n2 + 1;
        continue;
    end

    % Pulseq waveforms
    w = seq.waveforms_and_times(true, [n1 n2]);

    % pge2 interpreter waveforms 
    % and RF/ADC phase offset
    if ~isempty(xmlPath)
        d = read_segment_xml(sprintf('%sscan.xml.%04d', xmlPath, cnt));
        th = readthetaregisters(sprintf('%sscan.xml.%04d.ssp', xmlPath, cnt));
        %phaseOffset.pge2 = th(1).theta/2^23*pi;
    end

    % PulSeg object waveforms
    L = psq.loop(n1:n2, :);
    try
        S = getsegmentinstance(psq, i, sys_ge, L, 'rotate', true, 'interpolate', true);
    catch ME
        error(sprintf('(n = %d, i = %d): %s\n', n, i, ME.message));
    end

    plt.tmin = 0;
    plt.tmax = 0;

    %%
    %% check gradient waveforms 
    %%
    ax = {'gx','gy','gz'};
    for iax = 1:length(ax)
        % pge2 interpreter output (.xml files)
        if ~isempty(xmlPath)
            tt.pge2 = d(iax).time/1e6 - sys_ge.segment_dead_time;     
            g.pge2 = d(iax).value;
        end

        % Pulseq (.seq) object
        tt.seq = w{iax}(1,:);                   % sec
        g.seq = w{iax}(2,:)/sys_ge.gamma/100;    % Gauss/cm

        % PulSeg object (after pulseg.fromSeq() conversion)
        tt.psq = S.(ax{iax}).t - sys_ge.segment_dead_time;
        g.psq = S.(ax{iax}).signal;

        if ~isempty(xmlPath)
            plt.tmin = min(plt.tmin, min(tt.pge2(1)));
            plt.tmax = max(plt.tmax, max(tt.pge2(end)));
        else
            plt.tmin = min(plt.tmin, min(tt.psq(1)));
            plt.tmax = max(plt.tmax, max(tt.psq(end)));
        end

        % Check difference with seq object.
        % For traps/ext traps, interpreter waveform is piecewise constant 
        % so allow for small differences due to that fact.
        % In addition, increase tolerance to 1.5x (slew*4us) since seq.waveforms_and_times() 
        % may not be entirely accurate (?)

        if length(tt.seq) > 0
            % interpolate to tt.seq
            if ~isempty(xmlPath)
                [gi, I] = robustinterp1(tt.pge2, g.pge2, tt.seq);
            else
                [gi, I] = robustinterp1(tt.psq, g.psq, tt.seq);
            end
            tmp = g.seq(I);  % if I is full/sparse this is either row/column vector :(
            [err, Imaxdiff] = max(abs(gi(:)-tmp(:)));    % max difference, G/cm
        else
            err = 0;  % no gradient is present on the current axis
        end
        tol = 3 * sys_ge.slew_max * sys_ge.GRAD_UPDATE_TIME * 1e3;  % max allowed difference per 4us sample 

        if err > tol
            fprintf('%s waveform mismatch (segment at row %d: max diff %.3f G/cm at t = %.3f ms)\n', ax{iax}, n, err, 1e3*tt.seq(Imaxdiff(1)));
            ok = false;
            %doNextSegment = false;
        end

        if arg.plot
            sax = subplot(5,1,iax+2); 
            cla(sax);
            hold(sax, 'on');
            plot(1e3*tt.seq, g.seq, 'black-');  
            if ~isempty(xmlPath)
                plot(1e3*tt.pge2, g.pge2, 'r.-');
            else
                plot(1e3*tt.psq, g.psq, 'r.-');
            end
            ylabel(sprintf('%s\n(G/cm)', ax{iax}), 'Rotation', 0);
        end
    end

    %%
    %% check RF waveform
    %%

    % Pulseq waveform
    tt.seq = w{4}(1,:);                 % sec
    rf.seq = w{4}(2,:)/sys_ge.gamma;    % complex, Gauss

    % PulSeg/GE simulator waveform
    if ~isempty(xmlPath)
        % pge2 interpreter output (RHO and THETA)
        tt.rho = d(5).time/1e6 - sys_ge.segment_dead_time - sys_ge.psd_rf_wait;
        rho = d(5).value;                     % a.u.
        if max(abs(rho)) > 0                  % avoid divide by zero
            % Amplitude is in a.u. so here we just scale it based on the seq object (for now)
            rho = rho/max(abs(rho)) * max(abs(rf.seq));    % Gauss
        end

        tt.theta = d(6).time/1e6 - sys_ge.segment_dead_time - sys_ge.psd_rf_wait;
        theta = d(6).value/2^23*pi;  % + phaseOffset.pge2;  % radians. TODO: add phase and freq offsets
        theta = angle(exp(-1i*theta));  % minus sign since the pge2 interpreter conjugates the phase

        % construct complex waveform
        [thetai, I] = robustinterp1(tt.theta, theta, tt.rho);
        rf.pge2 = rho(I) .* exp(1i*thetai);
        tt.pge2 = tt.rho(I);

        plt.tmin = min(plt.tmin, min(tt.pge2(1)));
        plt.tmax = max(plt.tmax, max(tt.pge2(end)));
    else
        % PulSeg object waveform (output of pulseg.fromSeq)
        tt.psq = S.rf.t - sys_ge.segment_dead_time - sys_ge.psd_rf_wait;
        rf.psq = S.rf.signal;

        if length(rf.seq) > 0
            plt.tmin = min(plt.tmin, min(tt.psq(1)));
            plt.tmax = max(plt.tmax, max(tt.psq(end)));
        end
    end

    % Compare (non-zero samples only so it works for waveforms not starting/ending on zero at block boundary)
    err = 0;  % default
    if length(rf.seq) > 0
        I = find(abs(rf.seq) > 1e-12);
        if ~isempty(I)
            if ~isempty(xmlPath)
                % TODO: also compare phase
                I = find(abs(rf.pge2) > 1e-12);
                tmp_rf_pge2 = rf.pge2(I);
                I = find(abs(rf.seq) > 1e-12);
                tmp_rf_seq = rf.seq(I);
                err = 100 * rmse(abs(tmp_rf_pge2(:)), abs(tmp_rf_seq(:))) / rmse(tmp_rf_pge2(:), 0*tmp_rf_seq(:));
            else
                I = find(abs(rf.psq) > 1e-12);
                tmp_rf_psq = rf.psq(I);
                tmp_tt_psq = tt.psq(I);
                I = find(abs(rf.seq) > 1e-12);
                tmp_rf_seq = rf.seq(I);
                tmp_tt_seq = tt.seq(I);
                assert(norm(tmp_tt_seq(:) - tmp_tt_psq(:)) < 1e-7, 'RF timing in seq and psq objects do not match');
                if length(tmp_rf_psq) ~= length(tmp_rf_seq)
                    error('Number of non-zero RF waveform samples in seq and psq objects do not match');
                end
                err = 100 * rmse(abs(tmp_rf_psq(:)), abs(tmp_rf_seq(:))) / rmse(tmp_rf_psq(:), 0*tmp_rf_seq(:));
            end
        end
    end

    if err > arg.threshRFper
        fprintf('RF waveform mismatch (%.1f%%; segment at row %d)\n', err, n);
        ok = false;
    end

    if arg.plot
        sax = subplot(5,1,1); 
        cla(sax);
        hold(sax, 'on');
        if length(rf.seq) > 0
            plot(1e3*tt.seq, abs(rf.seq), 'black.');
            hold on
            if ~isempty(xmlPath)
                plot(1e3*tt.rho, rho, 'r.'); 
                legend('Pulseq', 'pge2'); 
            else
                plot(1e3*tt.psq, abs(rf.psq), 'r.'); 
                legend('Pulseq', 'psq'); 
            end
        else
            cla(sax)
        end
        ylabel(sprintf('|RF|\n(Gauss)'), 'Rotation', 0);
        title(sprintf('segment starting at row %d (count = %d)', n, cnt));

        sax = subplot(5,1,2); 
        cla(sax);
        hold(sax, 'on');
        if length(rf.seq) > 0
            plot(1e3*tt.seq, angle(rf.seq), 'black');
            if ~isempty(xmlPath)
                plot(1e3*tt.theta, theta, 'r.');
            else
                plot(1e3*tt.psq, angle(rf.psq), 'r.'); 
            end
        else
            cla(sax)
        end
        ylabel(sprintf('∠RF\n(radians)'), 'Rotation', 0);

        xlabel('time (ms)');

        % set plot limits
        for sp = 1:5
            subplot(5, 1, sp);
            xlim(1e3*[plt.tmin plt.tmax]);
            switch sp
                case 1
                    ylim([0 arg.b1PlotLim]);
                case 2
                    ylim(1.1* pi * [-1 1]);
                otherwise
                    ylim(1.1*sys_ge.g_max*[-1 1]);
            end
        end

        drawnow

        if ~axesLinked
            for sp = 1:5
                subplot(5, 1, sp); 
                ax{sp} = gca;
                grid on;
            end
            linkaxes([ax{1} ax{2} ax{3} ax{4} ax{5}], 'x');  % common zoom setting (along time axis) for all tiles
            axesLinked = true;
        end
    end

    if doNextSegment
        if arg.plot
            input('Press Enter key to plot next segment ', "s");
        end
        textprogressbar(n/psq.nMax*100);
        n = n2 + 1;
    else
        fprintf('Exiting\n');
        return;
    end
end

textprogressbar((n-1)/psq.nMax*100);
fprintf('\n');
