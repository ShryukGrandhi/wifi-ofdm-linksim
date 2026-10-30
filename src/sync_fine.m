function [ltf_start, cfo] = sync_fine(r, search_len, backoff)
%SYNC_FINE  Long-preamble timing and fine CFO.
%   Cross-correlates R with the known 64-sample LTF and picks the offset d
%   maximising |xc(d)| + |xc(d+64)| (both LTF copies). The window start is
%   moved BACKOFF samples earlier so that a strong late multipath tap does
%   not push the FFT window past the cyclic prefix; the resulting linear
%   phase is absorbed by the channel estimate. Fine CFO comes from the
%   64-sample repetition of the two LTF symbols.
[~, ~, ~, ltf_t] = preamble();
r = r(:);
b = conj(flipud(ltf_t));
y = filter(b, 1, r);
n = numel(r);
dmax = min(search_len, n - 128 - 63);
if dmax < 1
    error('sync_fine:len', 'signal too short');
end
xc = y(64:n);                         % xc(d) = sum conj(L) .* r(d:d+63)
metric = abs(xc(1:dmax)) + abs(xc(65:dmax+64));
[~, d] = max(metric);
ltf_start = max(d - backoff, 1);
a = r(d:d+63);
bb = r(d+64:d+127);
cfo = angle(sum(conj(a) .* bb)) / (2 * pi * 64);
end
