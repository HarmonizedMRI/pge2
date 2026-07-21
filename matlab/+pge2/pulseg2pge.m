function pge = pulseg2pge(pulseg_ir, varargin)
% PULSEG2PSG Convert PulSeg 2.0-alpha IR to legacy pge2 pge struct.
%
% Syntax:
%   pge = pge2.pulseg2pge(pulseg_ir)
%   pge = pge2.pulseg2pge(pulseg_ir, 'grad_raster_time', dt)
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
%       pge.pulseg_ir. Default: false.
%
% Output:
%   pge 
%       Legacy pge2-compatible struct with fields such as:
%
%           pge.loop
%           pge.segments
%           pge.parentBlocks
%           pge.nMax
%           pge.nSegments
%           pge.nParentBlocks
%           pge.nReadouts
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
%   - Legacy pge uses:
%         0  = constant delay
%        -1  = variable delay
%         1+ = explicit parent block indices
%   - PulSeg 2.0-alpha has separate adc_frequency_offset values. The legacy
%     loop does not have a column for ADC frequency. To avoid losing this
%     information completely, this adapter stores a row-aligned sidecar:
%
%         pge.loop_adc_frequency_offset
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

    %% Initialize pge

    pge = struct();

    pge.pge_version = 'legacy-from-pulseg';
    pge.source_pulseg_version = char(pulseg_ir.pulseg_version);

    if isfield(pulseg_ir, 'source_file')
        pge.source_file = pulseg_ir.source_file;
    end

    if isfield(pulseg_ir, 'creation_date')
        pge.creation_date = pulseg_ir.creation_date;
    end

    if isfield(pulseg_ir, 'duration')
        pge.duration = pulseg_ir.duration;
    end

    if arg.keep_pulseg_ir
        pge.pulseg_ir = pulseg_ir;
    end

    %% Count fields

    pge.nMax = size(loop2, 1);
    pge.n_max = pge.nMax;

    pge.nSegments = numel(pulseg_ir.virtual_segments);
    pge.n_segments = pge.nSegments;

    pge.nParentBlocks = numel(pulseg_ir.base_blocks);
    pge.n_parent_blocks = pge.nParentBlocks;

    pge.nReadouts = count_adc_events(pulseg_ir);
    pge.n_adc = pge.nReadouts;

    %% Build base-block-ID -> legacy parent-block-ID mapping

    base_ids = [pulseg_ir.base_blocks.id];

    % In PulSeg 2.0-alpha:
    %   explicit base block IDs are >= 2.
    %
    % In legacy pge:
    %   explicit parent block IDs are 1:nParentBlocks.
    %
    % We map according to the order in pulseg_ir.base_blocks.
    parent_ids = 1:numel(base_ids);

    %% Build parentBlocks

    pge.parentBlocks = struct('row', {}, 'block', {}, 'ID', {}, 'base_block_id', {});

    for p = 1:pge.nParentBlocks
        b = pulseg_ir.base_blocks(p).block;

        % Legacy code may expect the block itself to carry ID = parent index.
        if isstruct(b)
            b.ID = p;
        end

        pge.parentBlocks(p).row = NaN;  % filled below with first occurrence
        pge.parentBlocks(p).block = b;
        pge.parentBlocks(p).ID = p;
        pge.parentBlocks(p).base_block_id = pulseg_ir.base_blocks(p).id;
    end

    %% Build legacy segments

    pge.segments = struct( ...
        'nBlocksInSegment', {}, ...
        'TRID', {}, ...
        'ID', {}, ...
        'rows', {}, ...
        'blockIDs', {}, ...
        'virtual_segment_id', {} );

    for s = 1:pge.nSegments
        vs = pulseg_ir.virtual_segments(s);

        pge.segments(s).nBlocksInSegment = numel(vs.base_block_ids);

        if isfield(vs, 'TRID')
            pge.segments(s).TRID = vs.TRID;
        else
            pge.segments(s).TRID = vs.id;
        end

        % Legacy segment ID is the MATLAB array index.
        pge.segments(s).ID = s;

        % Fill below with first occurrence in the pge loop.
        pge.segments(s).rows = [];

        % Preserve original PulSeg virtual segment ID for traceability.
        pge.segments(s).virtual_segment_id = vs.id;

        % Convert PulSeg base_block_ids to legacy blockIDs.
        pge.segments(s).blockIDs = pulseg_base_ids_to_legacy_parent_ids( ...
            vs.base_block_ids, base_ids, parent_ids);
    end

    %% Convert loop2 to legacy 23-column pge.loop

    loop = zeros(pge.nMax, 23);

    % Sidecar for information not representable in legacy 23-column loop.
    pge.loop_adc_frequency_offset = zeros(pge.nMax, 1);

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

        assert(row_end <= pge.nMax, ...
            'Internal error while building pge.loop: row index exceeds nMax.');

        % Store first occurrence rows for this segment, matching legacy style.
        if isempty(pge.segments(s).rows)
            pge.segments(s).rows = row_start:row_end;
        end

        % Default legacy segment-level rotation is identity, written to the
        % last block row of the segment instance.
        R_last_flat = flatten_rotation_row_major(eye(3));

        for j = 1:nBlocksInSegment

            base_block_id = vs.base_block_ids(j);
            parent_id = pulseg_base_id_to_legacy_parent_id(base_block_id, base_ids, parent_ids);

            % Map current PulSeg loop row to old pge.loop columns.
            %
            % Segment/parent IDs.
            loop(row, 1) = s;
            loop(row, 2) = parent_id;

            % RF and gradient columns are column-compatible through col 11.
            loop(row, 3:11) = loop2(row, 3:11);

            % ADC phase.
            loop(row, 12) = loop2(row, 12);

            % Legacy loop has no ADC frequency column. Store sidecar.
            pge.loop_adc_frequency_offset(row) = loop2(row, 13);

            % Duration and trigger shift by one because loop2 has ADC freq.
            loop(row, 13) = loop2(row, 14);

            % Legacy trigger: place on first row of segment instance.
            if j == 1
                loop(row, 14) = loop2(row, 15);
            end

            % Parent block first occurrence row.
            if parent_id > 0 && isnan(pge.parentBlocks(parent_id).row)
                pge.parentBlocks(parent_id).row = row;
            end

            % Legacy rotation convention:
            %   use the last non-identity gradient-event rotation in the segment instance,
            %   then write it to the final block row of the segment instance.
            R = loop2(row,16:24);

            % Update only if this is a non-identity rotation.
            if ~is_identity_rotation_flat(R)
                R_last_flat = R;
            end

            row = row + 1;
        end

        % Write segment-level rotation to final row of this segment instance.
        loop(row_end, 15:23) = R_last_flat;
    end

    assert(row == pge.nMax + 1, ...
        'Internal error: expected to populate %d rows, populated %d.', ...
        pge.nMax, row - 1);

    pge.loop = loop;

    %% Compute legacy Emax fields

    pge = compute_segment_emax(pge);
end

function tf = is_identity_rotation_flat(Rflat)
%IS_IDENTITY_ROTATION_FLAT True if flattened rotation matrix is identity.

    Iflat = [1 0 0 0 1 0 0 0 1];

    tf = all(abs(Rflat - Iflat) < 1e-12);

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
% PULSEG_BASE_ID_TO_LEGACY_PARENT_ID Convert PulSeg base block ID to legacy pge ID.
%
% PulSeg 2.0-alpha:
%   0 = implicit constant delay
%   1 = implicit variable delay
%   >=2 = explicit base block ID
%
% Legacy pge:
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


function pge = compute_segment_emax(pge)
% COMPUTE_SEGMENT_EMAX Compute legacy segment Emax fields.
%
% Uses loop energy columns:
%
%   7  = Gx energy
%   9  = Gy energy
%   11 = Gz energy

    for s = 1:pge.nSegments
        pge.segments(s).Emax.val = 0;
        pge.segments(s).Emax.n = 1;
    end

    row = 1;

    while row <= pge.nMax
        s = pge.loop(row, 1);

        if s < 1 || s > pge.nSegments
            row = row + 1;
            continue;
        end

        nBlocksInSegment = pge.segments(s).nBlocksInSegment;

        if row + nBlocksInSegment - 1 > pge.nMax
            break;
        end

        row_start = row;
        rows = row_start:(row_start + nBlocksInSegment - 1);

        E_gx = sum(pge.loop(rows, 7));
        E_gy = sum(pge.loop(rows, 9));
        E_gz = sum(pge.loop(rows, 11));

        E_all = E_gx + E_gy + E_gz;

        if E_all > pge.segments(s).Emax.val
            pge.segments(s).Emax.val = E_all;
            pge.segments(s).Emax.n = row_start;
        end

        row = row + nBlocksInSegment;
    end
end
