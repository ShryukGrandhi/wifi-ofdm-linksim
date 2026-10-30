function out = depuncture(llr, rate, nmother)
%DEPUNCTURE  Re-insert zero LLRs (erasures) at punctured positions.
%   out = DEPUNCTURE(llr, rate, nmother) works column-wise: LLR is K x P and
%   OUT is nmother x P, where nmother is the rate-1/2 stream length.
p = puncture_pattern(rate);
if mod(nmother, numel(p)) ~= 0
    error('depuncture:len', 'mother length not a multiple of the pattern');
end
mask = repmat(p, nmother / numel(p), 1);
if size(llr, 1) ~= nnz(mask)
    error('depuncture:len', 'expected %d LLRs per column, got %d', ...
          nnz(mask), size(llr, 1));
end
out = zeros(nmother, size(llr, 2));
out(mask, :) = llr;
end
