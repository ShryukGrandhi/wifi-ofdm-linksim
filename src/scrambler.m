function [out, state] = scrambler(bits, state)
%SCRAMBLER  802.11 frame-synchronous scrambler, generator x^7 + x^4 + 1.
%   [out, state] = SCRAMBLER(bits, state) XORs the column vector BITS with
%   the scrambler sequence starting from the 7-element STATE (any nonzero
%   0/1 vector). The same call descrambles. STATE(1) is the newest bit.

bits = bits(:);
state = state(:);
if numel(state) ~= 7 || ~any(state)
    error('scrambler:state', 'state must be a nonzero 7-bit vector');
end
n = numel(bits);
seq = zeros(n, 1);
for k = 1:n
    fb = xor(state(4), state(7));
    seq(k) = fb;
    state = [fb; state(1:6)];
end
out = double(xor(bits, seq));
end
