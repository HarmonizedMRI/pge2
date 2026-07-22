function compilePGE_batch(scan_list, opts)
% compilePGE_batch  Compile a batch of Pulseq sequences for GE.
%
%   compilePGE_batch(scan_list, opts)
%
%   scan_list : Path to a text file with one entry per line:
%
%               <opuser1> <seq_file>
%
%               For example:
%
%                   20 localizer.seq
%                   21 gre.seq
%
%               Empty lines and lines beginning with '#' are ignored.
%
%   opts      : Options structure passed to compilePGE().
%
%   Each sequence is written to a .pge file having the same base name as
%   the corresponding .seq file.

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

    % Skip empty lines and comments
    if line == "" || startsWith(line, '#')
        continue
    end

    parts = strsplit(line);

    if numel(parts) < 2
        warning('compilePGE_batch:MalformedLine', ...
            'Skipping malformed line %d: "%s"', i, line);
        continue
    end

    opuser1 = str2double(parts(1));

    if isnan(opuser1)
        warning('compilePGE_batch:InvalidOpuser1', ...
            'Could not parse opuser1 on line %d: "%s"', i, line);
        continue
    end

    seqFile = parts(2);

    if ~isfile(seqFile)
        warning('compilePGE_batch:SequenceNotFound', ...
            'Skipping line %d because sequence file was not found: %s', ...
            i, seqFile);
        continue
    end

    [seqPath, seqName] = fileparts(seqFile);
    outputFile = seqName + ".pge";   % write to current working directory

    fprintf('\nCompiling %s -> %s\n', seqFile, outputFile);

    compilePGE(seqFile, opuser1, outputFile, opts);
end

