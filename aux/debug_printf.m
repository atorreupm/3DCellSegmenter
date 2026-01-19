function debug_printf(level, varargin)
% DEBUG_PRINTF Conditionally print debug info.
%
%   Inputs:
%   -------
%    level    - Debug message level.
%    message  - Message string.
%    ...      - Variable-length argument list.

global cfg;
	
if level >= cfg.SHOW_DEBUG_LEVEL
    fprintf('%s', sprintf(varargin{:}));
end
