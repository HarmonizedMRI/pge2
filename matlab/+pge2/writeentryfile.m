function writeentryfile(n, seq_name, varargin)
% writeentryfile - Convenience function for writing a pge .entry file
%
% function writeentryfile(n, seq_name, varargin)
% 
% Inputs
%   n         [1]         entry file number (CV1)
%   seq_name  string      .seq file name (with or without .seq/.pge/.mat extension)
%
% Input options
%   path     string      .pge file location on scanner/WTools simulator

% defaults
arg.path = '/srv/nfs/psd/usr/psd/pulseq/v7/sequences/';

% substitute with provided keyword arguments
arg = vararg_pair(arg, varargin);   % in ../

% use Linux/Win file separator 
arg.path = normalizepath(arg.path);

% strip .seq or .pge extension if present
seq_name = replace(seq_name, {'.seq', '.pge', '.mat'}, '');

% write .entry file
fid = fopen(['pge' num2str(n) '.entry'], 'wt');

fprintf(fid, '1\n');
fprintf(fid, '%s\n', strcat(arg.path, seq_name, '.pge'));

fclose(fid);
