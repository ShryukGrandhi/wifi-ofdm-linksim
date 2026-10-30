function out = interleave(bits, ncbps, nbpsc)
%INTERLEAVE  Apply the per-symbol 802.11a interleaver to a coded bit stream.
%   BITS has a multiple of NCBPS rows; columns are processed independently.
j = interleaver_index(ncbps, nbpsc);
[n, P] = size(bits);
if mod(n, ncbps) ~= 0
    error('interleave:len', 'length %d not a multiple of NCBPS=%d', n, ncbps);
end
x = reshape(bits, ncbps, []);
y = zeros(size(x));
y(j, :) = x;
out = reshape(y, n, P);
end
