
addpath ../../matlab   % +pge2 namespace

% get Pulseq toolbox
system('git clone git@github.com:pulseq/pulseq.git');
addpath pulseq/matlab

% get toolbox to convert .seq file to a PulSeg intermediate representation
%system('git clone --branch dev git@github.com:HarmonizedMRI/pulseg.git');
%addpath pulseg/matlab
%addpath(genpath('pulseg/matlab/third_party'));
addpath ~/github/HarmonizedMRI/pulseg/matlab/
addpath(genpath('~/github/HarmonizedMRI/pulseg/matlab/third_party'));
