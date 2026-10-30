function [cfo, d] = sync_coarse(r, search_len)
%SYNC_COARSE  Delay-and-correlate (Schmidl-Cox style) on the short preamble.
%   The STF repeats every 16 samples, so P(d) = sum conj(r(d+m)) r(d+m+16)
%   has a plateau whose phase is 2*pi*16*cfo. The CFO estimate is taken at
%   the peak of the normalised metric |P|^2 / R^2 within the first
%   SEARCH_LEN samples. Returns cfo in cycles/sample (range +-1/32) and the
%   index of the metric peak.
W = 32; lag = 16;
r = r(:);
nmax = min(search_len, numel(r) - W - lag);
if nmax < 1
    error('sync_coarse:len', 'signal too short');
end
c = conj(r(1:end-lag)) .* r(1+lag:end);
e = abs(r(1+lag:end)).^2;
P = filter(ones(W, 1), 1, c);          % P(n) sums c(n-W+1..n)
R = filter(ones(W, 1), 1, e);
P = P(W:W+nmax-1);
R = R(W:W+nmax-1);
M = abs(P).^2 ./ max(R.^2, eps);
% smooth over a short window so a single noisy sample cannot win
Ms = filter(ones(16, 1) / 16, 1, M);
[~, d] = max(Ms);
d = max(d - 8, 1);
cfo = angle(P(d)) / (2 * pi * lag);
end
