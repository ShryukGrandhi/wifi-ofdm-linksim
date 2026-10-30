function p = puncture_pattern(rate)
%PUNCTURE_PATTERN  Keep-mask applied to the interleaved [A B A B ...] stream.
%   rate is [num den]: [1 2], [2 3] or [3 4] (802.11a puncturing).
key = sprintf('%d/%d', rate(1), rate(2));
switch key
    case '1/2'
        p = [1 1];
    case '2/3'
        p = [1 1 1 0];             % A1 B1 A2 (B2 stolen)
    case '3/4'
        p = [1 1 1 0 0 1];         % A1 B1 A2 (B2 A3 stolen) B3
    otherwise
        error('puncture_pattern:rate', 'unsupported code rate %s', key);
end
p = logical(p(:));
end
