function translateFOVrf_batch(scan_list, Rxfile)
% translateFOVrf_batch  Process a batch of sequences listed in a text file.
%
%   translateFOVrf_batch(scan_list, Rxfile)
%
%   scan_list : path to text file with one entry per line:
%               <opuser1> <seq_name>
%               Lines beginning with '#' or empty lines are ignored.
%   Rxfile    : Text file containing output of `printSHM`, e.g., `printSHM > Rx.txt`

lines = readlines(scan_list);

for i = 1 : numel(lines)

    line = strtrim(lines(i));

    % Skip empty lines and comments
    if isempty(line) || line == "" || startsWith(line, '#')
        continue
    end

    parts = strsplit(line);
    if numel(parts) < 2
        warning('translateFOVrf_batch: skipping malformed line %d: "%s"', i, line);
        continue
    end

    opuser1 = str2double(parts(1));
    if isnan(opuser1)
        warning('translateFOVrf_batch: could not parse opuser1 on line %d: "%s"', i, line);
        continue
    end

    seq_name = parts(2);
    [~, seq_name, ~] = fileparts(seq_name);  % strips any extension

    out_name = seq_name + "_fov.pge";
    fprintf('Creating %s\n', out_name);
    translateFOVrf(seq_name, Rxfile, opuser1, out_name);

end

