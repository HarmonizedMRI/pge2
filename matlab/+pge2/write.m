function write(psq, fn, varargin)
% write - Write a PulSeg object to a binary file for execution on GE scanners
%
% function write(psq, fn, ...)
%
% Either 'params' or 'sys_ge' (kwargs) must be provided.
% 
% Inputs
%   psq       struct       PulSeg sequence object
%   fn        string       Output file name (.pge file)
%
% Options
%   sys_ge       struct       System hardware info, see pge2.opts()
%   params       struct       Various derived sequence parameters, obtained with:
%                             >> params = pge2.check(psq, sys_ge).
%                             If not specified, this script calls pge2.check(psq, sys_ge) for you.
%   pislquant    [1]          Number of ADC events at start of scan for setting Rx gain (default = 1)
%   gamma        [1]          Default: 42.576e6 (Hz/T)
%   checkHash    boolean      Ignore hash mismatch between params and psq object. Default: true

serialize(psq, fn, varargin);
