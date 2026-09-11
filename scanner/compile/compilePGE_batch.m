function compilePGE_batch(scan_list, opts)

% scan_list format:
% <opuser1> <pislquant> <soft_delay_input_ms|-> <seq_file>

arguments
    scan_list {mustBeTextScalar}
    opts
end

scan_list = string(scan_list);

if ischar(opts) || (isstring(opts) && isscalar(opts))
    opts = loadOptionsJSON(opts);
elseif ~isstruct(opts)
    error('compilePGE_batch:InvalidOptions', ...
        'opts must be a structure or the path to a JSON options file.');
end

if ~isfile(scan_list)
    error('compilePGE_batch:ScanListNotFound', ...
        'Scan-list file not found: %s', scan_list);
end

lines = readlines(scan_list);
for i = 1:numel(lines)
    line = strtrim(lines(i));
    if line == "" || startsWith(line, '#')
        continue
    end

    parts = strsplit(line);
    if numel(parts) ~= 4
        warning('compilePGE_batch:MalformedLine', ...
            ['Skipping malformed line %d. Expected: ' ...
             '<opuser1> <pislquant> <soft_delay_input_ms|-> <seq_file>'], i);
        continue
    end

    opuser1 = str2double(parts(1));
    pislquant = str2double(parts(2));

    if isnan(opuser1) || isnan(pislquant)
        warning('compilePGE_batch:InvalidNumericField', ...
            'Could not parse opuser1 or pislquant on line %d.', i);
        continue
    end

    if parts(3) == "-"
        soft_delay_input_ms = [];
    else
        soft_delay_input_ms = str2double(parts(3));
        if isnan(soft_delay_input_ms)
            warning('compilePGE_batch:InvalidSoftDelayInput', ...
                'Invalid soft_delay_input_ms on line %d.', i);
            continue
        end
    end

    seqFile = parts(4);
    if ~isfile(seqFile)
        warning('compilePGE_batch:SequenceNotFound', ...
            'Skipping line %d because sequence file was not found: %s', ...
            i, seqFile);
        continue
    end

    [~, seqName] = fileparts(seqFile);
    outputFile = seqName + ".pge";

    fprintf('\nCompiling %s -> %s\n', seqFile, outputFile);

    if isempty(soft_delay_input_ms)
        compilePGE(seqFile, opuser1, pislquant, outputFile, opts);
    else
        compilePGE(seqFile, opuser1, pislquant, outputFile, opts, ...
            'soft_delay_input_ms', soft_delay_input_ms);
    end
end
