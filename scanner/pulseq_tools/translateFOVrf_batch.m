function translateFOVrf_batch(scan_list, Rxfile)

lines = readlines(scan_list);

for i = 1:numel(lines)

    line = strtrim(lines(i));
    if line == "" || startsWith(line,"#")
        continue
    end

    parts = strsplit(line);
    opuser1 = str2num(parts(1));
    seq_name = parts(2);

    fprintf('Creating %s\n', seq_name + "_fov.pge");
    translateFOVrf(seq_name, Rxfile, opuser1, seq_name + "_fov.pge");

end
