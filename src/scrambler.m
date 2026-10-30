function [out, state] = scrambler(bits, state)
%SCRAMBLER  802.11 frame-synchronous scrambler, generator x^7 + x^4 + 1.
%   [out, state] = SCRAMBLER(bits, state) XORs the column vector BITS with
%   the scrambler sequence starting from the 7-element STATE (any nonzero
%   0/1 vector). The same call descrambles. STATE(1) is the newest bit.
%
%   The sequence is an m-sequence of period 127, so only one period is
%   generated bit by bit and then tiled over the input.

bits = bits(:);
state = state(:);
if numel(state) ~= 7 || ~any(state)
    error('scrambler:state', 'state must be a nonzero 7-bit vector');
end
n = numel(bits);
per = zeros(127, 1);
s = state;
for k = 1:127
    fb = xor(s(4), s(7));
    per(k) = fb;
    s = [fb; s(1:6)];
end
seq = per(mod(0:n-1, 127) + 1);
out = double(xor(bits, seq));
% register after n shifts: the last 7 generated bits, newest first
hist = [flipud(state); seq];
state = flipud(hist(end-6:end));
end
