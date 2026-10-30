function bits = viterbi_decode(llr, terminated)
%VITERBI_DECODE  Soft-input Viterbi decoder for the 802.11 K=7 rate-1/2 code.
%   bits = VITERBI_DECODE(llr) decodes the columns of LLR independently.
%   LLR is 2T x P with rows ordered [A1 B1 A2 B2 ...]; positive values favour
%   bit 0 and zeros mark erasures (punctured bits). BITS is T x P.
%
%   All P codewords share one add-compare-select loop: path metrics are a
%   64 x P matrix, so the per-step interpreter overhead is paid once per
%   trellis step instead of once per packet.
%
%   terminated (default true): trace back from state 0 (tail bits present).
%   Otherwise trace back from the best final state.

if nargin < 2
    terminated = true;
end
[n2, P] = size(llr);
if mod(n2, 2) ~= 0
    error('viterbi_decode:len', 'LLR rows must be even (pairs of A/B bits)');
end
T = n2 / 2;
t = viterbi_trellis();

la = llr(1:2:end, :);     % T x P
lb = llr(2:2:end, :);

pm = -inf(64, P);
pm(1, :) = 0;
dec = false(64, P, T);    % decision: which predecessor (b) survived

for k = 1:T
    a = la(k, :);
    b = lb(k, :);
    m0 = pm(t.prev0, :) + t.sa0 * a + t.sb0 * b;
    m1 = pm(t.prev1, :) + t.sa1 * a + t.sb1 * b;
    pick1 = m1 > m0;
    pm = m0;
    pm(pick1) = m1(pick1);
    dec(:, :, k) = pick1;
    if mod(k, 64) == 0
        pm = bsxfun(@minus, pm, max(pm, [], 1));   % keep metrics bounded
    end
end

if terminated
    state = zeros(1, P);
else
    [~, idx] = max(pm, [], 1);
    state = idx - 1;
end

bits = zeros(T, P);
cols = 0:P-1;
for k = T:-1:1
    bits(k, :) = floor(state / 32);
    b = dec(state + 1 + 64 * cols + 64 * P * (k - 1));
    state = mod(state, 32) * 2 + b;
end
end
