function coded = conv_encode(bits)
%CONV_ENCODE  Rate-1/2, constraint length 7 convolutional encoder (802.11).
%   coded = CONV_ENCODE(bits) encodes the 0/1 column vector BITS with
%   generators g0 = 133 (octal) and g1 = 171 (octal), starting from the
%   all-zero state. Output is [A1 B1 A2 B2 ...]' of length 2*numel(bits).
%   The caller appends 6 zero tail bits to return the encoder to state 0.

[g0, g1] = conv_generators();
bits = double(bits(:));
a = mod(filter(g0, 1, bits), 2);
b = mod(filter(g1, 1, bits), 2);
coded = reshape([a b]', [], 1);
end
