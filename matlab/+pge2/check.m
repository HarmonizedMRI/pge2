function params = check(psq, sysGE, varargin)
% check - Check compatibility of a PulSeg sequence against GE scanner hardware parameters
%
% function params = check(psq, sysGE, ...)
%
% The following are checked:
%  - Sequence block timing
%  - Peak b1 and gradient amplitude/slew
%  - PNS (for one segment at a time)
%
% Inputs
%   psq       struct         PulSeg sequence object, see fromSeq()
%   sysGE     struct         System hardware info, see pge2.opts()
%
% Input options
%   PNSwt     [3]   PNS x/y/z/ channel weights. See pge2.pns().
%    
% To determine if the pge2 interpreter output matches
% the original .seq file, use pge2.validate(...)

arg.PNSwt = [1 1 1];

arg = vararg_pair(arg, varargin);   % in ../

tol = 1e-7;   % timing tolerance. Matches 'eps' in the pge2 EPIC code

% initialize return value
params.b1max = 0;      % max RF amplitude
params.gmax = 0;       % max single-axis gradient amplitude [G/cm]
params.smax = 0;       % max single-axis slew rate in sequence, G/cm/ms
params.PNSwt = arg.PNSwt;
params.hash = DataHash(psq);

% Check parent block timing.
% Parent blocks are 'virtual' (waveform amplitudes are arbitrary/normalized), so only check
% timing here; waveforms will be checked below for each segment instance in the scan loop.
for p = 1:psq.nParentBlocks         % we use 'p' to count parent blocks here and in the EPIC code
    b = psq.parentBlocks(p).block;
    try
        checkblocktiming(b, sysGE);
    catch ME
        error('Error in parent block %d: %s\n', p, ME.message);
    end
end

% check all segment instances
n = 1;    % row (block) counter in psq.loop
textprogressbar('pge2.check(): Checking scan loop: ');
while n < psq.nMax 
    % get segment instance
    i = psq.loop(n,1);  % segment index
    L = psq.loop(n:(n-1+psq.segments(i).nBlocksInSegment), :);  % dynamic info
    try
        S = getsegmentinstance(psq, i, sysGE, L, 'rotate', true, 'interpolate', true);
    catch ME
        error(sprintf('(n = %d, i = %d): %s\n', n, i, ME.message));
    end

    % check it
    try
        v = checksegment(S, sysGE, 'PNSwt', arg.PNSwt);
    catch ME
        error(sprintf('(segment %d, row %d): %s', i, n, ME.message));
    end

    params.b1max = max(params.b1max, v.b1max);
    params.gmax = max(params.gmax, v.gmax);
    params.smax = max(params.smax, v.smax);

    textprogressbar(n/psq.nMax*100);

    n = n + psq.segments(i).nBlocksInSegment;
end
textprogressbar((n-1)/psq.nMax*100);

textprogressbar(' ok'); 
