function out = deinterleave(vals, ncbps, nbpsc)
%DEINTERLEAVE  Inverse of INTERLEAVE; works on bits or LLRs.
j = interleaver_index(ncbps, nbpsc);
[n, P] = size(vals);
if mod(n, ncbps) ~= 0
    error('deinterleave:len', 'length %d not a multiple of NCBPS=%d', n, ncbps);
end
x = reshape(vals, ncbps, []);
out = reshape(x(j, :), n, P);
end
