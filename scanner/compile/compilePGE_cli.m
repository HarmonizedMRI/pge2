function compilePGE_cli(seqFile, opuser1, pislquant, outputFile, configFile, varargin)

opuser1 = str2double(opuser1);
pislquant = str2double(pislquant);

if isnan(opuser1)
    error('compilePGE_cli:InvalidOpuser1', 'opuser1 must be numeric.');
end
if isnan(pislquant)
    error('compilePGE_cli:InvalidPislquant', 'pislquant must be numeric.');
end

opts = loadOptionsJSON(configFile);

soft_delay_input_ms = [];
noTranslateFOV = false;

i = 1;
while i <= numel(varargin)
    arg = string(varargin{i});
    switch arg
        case "--soft-delay-input-ms"
            if i == numel(varargin)
                error('compilePGE_cli:MissingSoftDelayValue', ...
                    '--soft-delay-input-ms requires a value.');
            end
            soft_delay_input_ms = str2double(varargin{i + 1});
            if isnan(soft_delay_input_ms)
                error('compilePGE_cli:InvalidSoftDelayValue', ...
                    '--soft-delay-input-ms must be numeric.');
            end
            i = i + 2;
        case "--no-translate-fov"
            noTranslateFOV = true;
            i = i + 1;
        otherwise
            error('compilePGE_cli:UnknownOption', ...
                'Unknown option: %s', arg);
    end
end

if noTranslateFOV && isfield(opts, 'translateFOV')
    opts = rmfield(opts, 'translateFOV');
end

if isempty(soft_delay_input_ms)
    compilePGE(seqFile, opuser1, pislquant, outputFile, opts);
else
    compilePGE(seqFile, opuser1, pislquant, outputFile, opts, ...
        'soft_delay_input_ms', soft_delay_input_ms);
end
end
