function pge_ir = pulseg2pge(pulseg_ir, varargin)
% PULSEG2PSG Convert PulSeg 2.0-alpha IR to legacy pge2 pge_ir struct.
%
% Syntax:
%   pge_ir = pge2.pulseg2pge(pulseg_ir)
%   pge_ir = pge2.pulseg2pge(pulseg_ir, 'grad_raster_time', dt)
%
% Description:
%   PULSEG2PSG converts a PulSeg 2.0-alpha IR struct into the legacy `psq`/`psg`
%   struct representation expected by older pge2 tools.
%
%   This function is intended as a compatibility adapter during the PulSeg
%   2.0-alpha transition. The PulSeg IR remains the authoritative
%   representation.
%
% Inputs:
%   pulseg_ir
%       PulSeg 2.0-alpha IR struct.
%
% Options:
%   grad_raster_time
%       Gradient raster time in seconds, used by pulseg.stream2loop() for
%       sampled/arbitrary gradient energy calculations.
%
%   keep_pulseg_ir
%       Logical flag. If true, store the original PulSeg IR inside
%       pge_ir.pulseg_ir. Default: false.
%
% Output:
%   pge_ir 
%       Legacy pge2-compatible struct with fields such as:
%
%           pge_ir.loop
%           pge_ir.segments
%           pge_ir.parentBlocks
%           pge_ir.nMax
%           pge_ir.nSegments
%           pge_ir.nParentBlocks
%           pge_ir.nReadouts
%
% Legacy loop column convention:
%
%   Col  1: segment index
%   Col  2: parent block ID
%              -1 = implicit variable delay
%               0 = implicit constant delay
%              >0 = parentBlocks index
%   Col  3: RF amplitude scale
%   Col  4: RF phase offset
%   Col  5: RF frequency offset
%   Col  6: Gx amplitude scale
%   Col  7: Gx energy
%   Col  8: Gy amplitude scale
%   Col  9: Gy energy
%   Col 10: Gz amplitude scale
%   Col 11: Gz energy
%   Col 12: ADC phase offset
%   Col 13: block duration
%   Col 14: physio trigger
%   Col 15-23: row-major flattened 3x3 rotation matrix
%
% Notes:
%   - PulSeg 2.0-alpha uses base block IDs 0, 1, 2, ...
%     where 0 and 1 are reserved implicit delay blocks.
%   - Legacy pge_ir uses:
%         0  = constant delay
%        -1  = variable delay
%         1+ = explicit parent block indices
%   - PulSeg 2.0-alpha has separate adc_frequency_offset values. The legacy
%     loop does not have a column for ADC frequency. To avoid losing this
%     information completely, this adapter stores a row-aligned sidecar:
%
%         pge_ir.loop_adc_frequency_offset
%
%     Existing legacy pge2 code can ignore this field.

    %% Parse inputs

    arg.grad_raster_time = [];
    arg.keep_pulseg_ir = false;
    arg = vararg_pair(arg, varargin);

    assert(isstruct(pulseg_ir), ...
        'Input must be a PulSeg IR struct.');

    assert(isfield(pulseg_ir, 'pulseg_version'), ...
        'Input does not appear to be a PulSeg IR struct: missing pulseg_version.');

    if exist('pulseg.validate_ir', 'file') == 2
        pulseg.validate_ir(pulseg_ir);
    end

    %% Build current PulSeg loop first

    dt = arg.grad_raster_time;
    loop2 = pulseg.stream2loop(pulseg_ir, dt);

    % Expected current loop2 column convention from pulseg.stream2loop:
    %
    %   1       virtual segment ID
    %   2       PulSeg base block ID
    %   3       RF amplitude
    %   4       RF phase
    %   5       RF frequency
    %   6       Gx amplitude
    %   7       Gx energy
    %   8       Gy amplitude
    %   9       Gy energy
    %   10      Gz amplitude
    %   11      Gz energy
    %   12      ADC phase
    %   13      ADC frequency
    %   14      block duration
    %   15      physio trigger
    %   16:24   row-major rotation matrix

    assert(size(loop2, 2) >= 24, ...
        'Expected pulseg.stream2loop() to return at least 24 columns.');

    %% Initialize pge_ir

    pge_ir = struct();

    pge_ir.pge_ir_version = 'legacy-from-pulseg';
    pge_ir.source_pulseg_version = char(pulseg_ir.pulseg_version);

    if isfield(pulseg_ir, 'source_file')
        pge_ir.source_file = pulseg_ir.source_file;
    end

    if isfield(pulseg_ir, 'creation_date')
        pge_ir.creation_date = pulseg_ir.creation_date;
    end

    if isfield(pulseg_ir, 'duration')
        pge_ir.duration = pulseg_ir.duration;
    end

    if arg.keep_pulseg_ir
        pge_ir.pulseg_ir = pulseg_ir;
    end

    %% Count fields

    pge_ir.nMax = size(loop2, 1);
    pge_ir.n_max = pge_ir.nMax;

    pge_ir.nSegments = numel(pulseg_ir.virtual_segments);
    pge_ir.n_segments = pge_ir.nSegments;

    pge_ir.nParentBlocks = numel(pulseg_ir.base_blocks);
    pge_ir.n_parent_blocks = pge_ir.nParentBlocks;

    pge_ir.nReadouts = count_adc_events(pulseg_ir);
    pge_ir.n_adc = pge_ir.nReadouts;

    %% Build base-block-ID -> legacy parent-block-ID mapping

    base_ids = [pulseg_ir.base_blocks.id];

    % In PulSeg 2.0-alpha:
    %   explicit base block IDs are >= 2.
    %
    % In legacy pge_ir:
    %   explicit parent block IDs are 1:nParentBlocks.
    %
    % We map according to the order in pulseg_ir.base_blocks.
    parent_ids = 1:numel(base_ids);

    %% Build parentBlocks

    pge_ir.parentBlocks = struct('row', {}, 'block', {}, 'ID', {}, 'base_block_id', {});

    for p = 1:pge_ir.nParentBlocks
        b = pulseg_ir.base_blocks(p).block;

        % Legacy code may expect the block itself to carry ID = parent index.
        if isstruct(b)
            b.ID = p;
        end

        pge_ir.parentBlocks(p).row = NaN;  % filled below with first occurrence
        pge_ir.parentBlocks(p).block = b;
        pge_ir.parentBlocks(p).ID = p;
        pge_ir.parentBlocks(p).base_block_id = pulseg_ir.base_blocks(p).id;
    end

    %% Build legacy segments

    pge_ir.segments = struct( ...
        'nBlocksInSegment', {}, ...
        'TRID', {}, ...
        'ID', {}, ...
        'rows', {}, ...
        'blockIDs', {}, ...
        'virtual_segment_id', {} );

    for s = 1:pge_ir.nSegments
        vs = pulseg_ir.virtual_segments(s);

        pge_ir.segments(s).nBlocksInSegment = numel(vs.base_block_ids);

        if isfield(vs, 'TRID')
            pge_ir.segments(s).TRID = vs.TRID;
        else
            pge_ir.segments(s).TRID = vs.id;
        end

        % Legacy segment ID is the MATLAB array index.
        pge_ir.segments(s).ID = s;

        % Fill below with first occurrence in the pge_ir loop.
        pge_ir.segments(s).rows = [];

        % Preserve original PulSeg virtual segment ID for traceability.
        pge_ir.segments(s).virtual_segment_id = vs.id;

        % Convert PulSeg base_block_ids to legacy blockIDs.
        pge_ir.segments(s).blockIDs = pulseg_base_ids_to_legacy_parent_ids( ...
            vs.base_block_ids, base_ids, parent_ids);
    end

    %% Convert loop2 to legacy 23-column pge_ir.loop

    loop = zeros(pge_ir.nMax, 23);

    % Sidecar for information not representable in legacy 23-column loop.
    pge_ir.loop_adc_frequency_offset = zeros(pge_ir.nMax, 1);

    vs_ids = [pulseg_ir.virtual_segments.id];

    row = 1;

    for k = 1:numel(pulseg_ir.execution_stream)

        inst = pulseg_ir.execution_stream(k);

        s = find(vs_ids == inst.virtual_segment_id, 1);
        assert(~isempty(s), ...
            'Could not find virtual segment ID %d.', inst.virtual_segment_id);

        vs = pulseg_ir.virtual_segments(s);
        nBlocksInSegment = numel(vs.base_block_ids);

        row_start = row;
        row_end = row + nBlocksInSegment - 1;

        assert(row_end <= pge_ir.nMax, ...
            'Internal error while building pge_ir.loop: row index exceeds nMax.');

        % Store first occurrence rows for this segment, matching legacy style.
        if isempty(pge_ir.segments(s).rows)
            pge_ir.segments(s).rows = row_start:row_end;
        end

        % Default legacy segment-level rotation is identity, written to the
        % last block row of the segment instance.
        R_last_flat = flatten_rotation_row_major(eye(3));

        for j = 1:nBlocksInSegment

            base_block_id = vs.base_block_ids(j);
            parent_id = pulseg_base_id_to_legacy_parent_id(base_block_id, base_ids, parent_ids);

            % Map current PulSeg loop row to old pge_ir.loop columns.
            %
            % Segment/parent IDs.
            loop(row, 1) = s;
            loop(row, 2) = parent_id;

            % RF and gradient columns are column-compatible through col 11.
            loop(row, 3:11) = loop2(row, 3:11);

            % ADC phase.
            loop(row, 12) = loop2(row, 12);

            % Legacy loop has no ADC frequency column. Store sidecar.
            pge_ir.loop_adc_frequency_offset(row) = loop2(row, 13);

            % Duration and trigger shift by one because loop2 has ADC freq.
            loop(row, 13) = loop2(row, 14);

            % Legacy trigger: place on first row of segment instance.
            if j == 1
                loop(row, 14) = loop2(row, 15);
            end

            % Parent block first occurrence row.
            if parent_id > 0 && isnan(pge_ir.parentBlocks(parent_id).row)
                pge_ir.parentBlocks(parent_id).row = row;
            end

            % Legacy rotation convention:
            %   use the last gradient-event rotation in the segment instance,
            %   then write it to the final block row of the segment instance.
            if base_block_has_gradient(pulseg_ir, base_block_id)
                R_last_flat = loop2(row, 16:24);
            end

            row = row + 1;
        end

        % Write segment-level rotation to final row of this segment instance.
        loop(row_end, 15:23) = R_last_flat;
    end

    assert(row == pge_ir.nMax + 1, ...
        'Internal error: expected to populate %d rows, populated %d.', ...
        pge_ir.nMax, row - 1);

    pge_ir.loop = loop;

    %% Compute legacy Emax fields

    pge_ir = compute_segment_emax(pge_ir);
end


function n_adc = count_adc_events(pulseg_ir)
% COUNT_ADC_EVENTS Count ADC events across all execution stream instances.

    n_adc = 0;

    for k = 1:numel(pulseg_ir.execution_stream)
        if isfield(pulseg_ir.execution_stream(k), 'adc_phase_offset')
            n_adc = n_adc + numel(pulseg_ir.execution_stream(k).adc_phase_offset);
        end
    end
end


function parent_ids_out = pulseg_base_ids_to_legacy_parent_ids(base_block_ids, base_ids, parent_ids)
% PULSEG_BASE_IDS_TO_LEGACY_PARENT_IDS Convert vector of PulSeg base IDs.

    parent_ids_out = zeros(size(base_block_ids));

    for j = 1:numel(base_block_ids)
        parent_ids_out(j) = pulseg_base_id_to_legacy_parent_id( ...
            base_block_ids(j), base_ids, parent_ids);
    end
end


function parent_id = pulseg_base_id_to_legacy_parent_id(base_block_id, base_ids, parent_ids)
% PULSEG_BASE_ID_TO_LEGACY_PARENT_ID Convert PulSeg base block ID to legacy pge_ir ID.
%
% PulSeg 2.0-alpha:
%   0 = implicit constant delay
%   1 = implicit variable delay
%   >=2 = explicit base block ID
%
% Legacy pge_ir:
%   0 = constant delay
%  -1 = variable delay
%   >=1 = parent block index

    if base_block_id == 0
        parent_id = 0;
        return;
    end

    if base_block_id == 1
        parent_id = -1;
        return;
    end

    idx = find(base_ids == base_block_id, 1);

    assert(~isempty(idx), ...
        'PulSeg base block ID %d does not exist in base_blocks.', base_block_id);

    parent_id = parent_ids(idx);
end


function tf = base_block_has_gradient(pulseg_ir, base_block_id)
% BASE_BLOCK_HAS_GRADIENT True if explicit base block contains any gradient event.

    tf = false;

    if base_block_id == 0 || base_block_id == 1
        return;
    end

    base_ids = [pulseg_ir.base_blocks.id];
    p = find(base_ids == base_block_id, 1);

    assert(~isempty(p), ...
        'Could not find base block ID %d.', base_block_id);

    b = pulseg_ir.base_blocks(p).block;

    tf = has_event(b, 'gx') || has_event(b, 'gy') || has_event(b, 'gz');
end


function tf = has_event(b, fieldname)
% HAS_EVENT True if a block contains a nonempty event field.

    tf = isstruct(b) && isfield(b, fieldname) && ~isempty(b.(fieldname));
end


function r = flatten_rotation_row_major(R)
% FLATTEN_ROTATION_ROW_MAJOR Flatten 3x3 matrix in row-major order.

    assert(all(size(R) == [3 3]), ...
        'Rotation matrix must be 3 x 3.');

    r = reshape(R.', 1, []);
end


function pge_ir = compute_segment_emax(pge_ir)
% COMPUTE_SEGMENT_EMAX Compute legacy segment Emax fields.
%
% Uses loop energy columns:
%
%   7  = Gx energy
%   9  = Gy energy
%   11 = Gz energy

    for s = 1:pge_ir.nSegments
        pge_ir.segments(s).Emax.val = 0;
        pge_ir.segments(s).Emax.n = 1;
    end

    row = 1;

    while row <= pge_ir.nMax
        s = pge_ir.loop(row, 1);

        if s < 1 || s > pge_ir.nSegments
            row = row + 1;
            continue;
        end

        nBlocksInSegment = pge_ir.segments(s).nBlocksInSegment;

        if row + nBlocksInSegment - 1 > pge_ir.nMax
            break;
        end

        row_start = row;
        rows = row_start:(row_start + nBlocksInSegment - 1);

        E_gx = sum(pge_ir.loop(rows, 7));
        E_gy = sum(pge_ir.loop(rows, 9));
        E_gz = sum(pge_ir.loop(rows, 11));

        E_all = E_gx + E_gy + E_gz;

        if E_all > pge_ir.segments(s).Emax.val
            pge_ir.segments(s).Emax.val = E_all;
            pge_ir.segments(s).Emax.n = row_start;
        end

        row = row + nBlocksInSegment;
    end
end
