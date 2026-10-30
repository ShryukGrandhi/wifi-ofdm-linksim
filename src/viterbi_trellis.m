function t = viterbi_trellis()
%VITERBI_TRELLIS  Precomputed predecessor tables for the K=7 802.11 code.
%   State s (0..63) holds the previous six inputs, newest in the MSB:
%   next = u*32 + floor(s/2). Each next state ns has two predecessors
%   p = mod(ns,32)*2 + b, b in {0,1}, both reached with input u = floor(ns/32).
%
%   Fields (64 x 1, indexed by ns+1):
%     prev0, prev1  predecessor index (1-based) for b = 0 / 1
%     sa0, sb0      +1/-1 sign of expected A/B bit on the b = 0 branch
%     sa1, sb1      same for the b = 1 branch
%   sign = 1 - 2*bit, so a branch metric is sa*llrA + sb*llrB.

persistent cached;
if ~isempty(cached)
    t = cached;
    return;
end
[g0, g1] = conv_generators();
ns = (0:63)';
u = floor(ns / 32);
t.prev0 = zeros(64, 1); t.prev1 = zeros(64, 1);
t.sa0 = zeros(64, 1); t.sb0 = zeros(64, 1);
t.sa1 = zeros(64, 1); t.sb1 = zeros(64, 1);
for i = 1:64
    for b = 0:1
        p = mod(ns(i), 32) * 2 + b;
        reg = [u(i), bitget(p, 6:-1:1)];     % [u_t u_{t-1} ... u_{t-6}]
        oa = mod(sum(reg .* g0), 2);
        ob = mod(sum(reg .* g1), 2);
        if b == 0
            t.prev0(i) = p + 1; t.sa0(i) = 1 - 2*oa; t.sb0(i) = 1 - 2*ob;
        else
            t.prev1(i) = p + 1; t.sa1(i) = 1 - 2*oa; t.sb1(i) = 1 - 2*ob;
        end
    end
end
cached = t;
end
