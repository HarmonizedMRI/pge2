function opts = prepare_scan_opts()

% ----- PulSeg import -----------------------------------------------------

% Soft delay 'input' value (ms)
opts.pulseg_import.soft_delay_input_ms = 700;

% ----- Optional FOV translation ------------------------------------------

% Output of command-line function `printSHM`
%opts.translateFOV.Rxfile = 'Rx.txt';

% ----- GE scanner definition ---------------------------------------------

psd_rf_wait  = 100e-6;  % sec
psd_grd_wait = 100e-6;  % sec
b1_max       = 0.25;    % Gauss
g_max        = 5;       % Gauss/cm
slew_max     = 20;      % Gauss/cm/msec
coil         = 'xrm';

opts.sys_ge = pge2.opts( ...
    psd_rf_wait, psd_grd_wait, ...
    b1_max, g_max, slew_max, coil);

% ----- pge2.import() -----------------------------------------------------

opts.pge_import.grad_raster_time = 4e-6;

% ----- pge2.check() ------------------------------------------------------

opts.pge_check.PNSwt = [1 1 1];

% ----- pge2.serialize() --------------------------------------------------

opts.pge_serialize.pislquant = 10;
opts.pge_serialize.checkHash = true;

% ----- pge2.writeentryfile() ---------------------------------------------
opts.pge_writeentryfile.path = '/srv/nfs/psd/usr/psd/pulseq/v7/sequences/';
