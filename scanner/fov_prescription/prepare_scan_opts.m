function opts = prepare_scan_opts()

% soft delay 'input' value
opts.pulseg_import.soft_delay_input_ms = 700;

% output of command-line function `printSHM`
opts.translateFOV.Rxfile = 'Rx.txt';    

% gradient raster time (used to calculate gradient heating)
opts.pge2_import.grad_raster_time = 4e-6;  % sec

% Peripheral nerve stimulation weights along logical x/y/z directions
opts.check.PNSwt = [1 1 1];  

% number of ADC events at start of scan to use for receive gain calibration (R1/R2)
opts.serialize.pislquant = 10;  

% assert that parameters returned by pge2.check() are used when serializing
opts.serialize.checkHash = true;

% GE scanner parameters
psd_rf_wait  = 100e-6;   % RF–gradient delay (s), scanner-specific
psd_grd_wait = 100e-6;   % ADC–gradient delay (s), scanner-specific
b1_max   = 0.25;         % Gauss
g_max    = 5;            % Gauss/cm
slew_max = 20;           % Gauss/cm/ms
coil     = 'xrm';        % See pge2.opts(). 'xrm' (MR750), 'hrmw' (Premier), 'magnus', ...

opts.sys_ge = pge2.opts(psd_rf_wait, psd_grd_wait, b1_max, g_max, slew_max, coil);

