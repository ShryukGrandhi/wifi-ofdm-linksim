function j = interleaver_index(ncbps, nbpsc)
%INTERLEAVER_INDEX  802.11a block interleaver permutation for one OFDM symbol.
%   Input bit k (1-based) is written to output position j(k).
%   First permutation: adjacent coded bits go to non-adjacent subcarriers.
%   Second permutation: adjacent bits alternate between more and less
%   reliable constellation bit positions.
k = (0:ncbps-1)';
i = (ncbps / 16) * mod(k, 16) + floor(k / 16);
s = max(nbpsc / 2, 1);
j = s * floor(i / s) + mod(i + ncbps - floor(16 * i / ncbps), s);
j = j + 1;
end
