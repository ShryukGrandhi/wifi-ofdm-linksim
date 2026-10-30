function out = puncture(coded, rate)
%PUNCTURE  Remove bits from a rate-1/2 stream to reach RATE ([num den]).
p = puncture_pattern(rate);
coded = coded(:);
if mod(numel(coded), numel(p)) ~= 0
    error('puncture:len', 'coded length %d not a multiple of pattern %d', ...
          numel(coded), numel(p));
end
mask = repmat(p, numel(coded) / numel(p), 1);
out = coded(mask);
end
