function test_interleaver()
for nbpsc = [1 2 4 6]
    ncbps = 48 * nbpsc;
    j = interleaver_index(ncbps, nbpsc);
    assert(isequal(sort(j), (1:ncbps)'), 'interleaver is not a permutation');
    % adjacent coded bits land on subcarriers at least 3 apart
    sc = floor((j - 1) / nbpsc);
    assert(all(abs(diff(sc)) >= 3), 'adjacent bits on nearby subcarriers');
    % second permutation: 16 consecutive coded bits (one per subcarrier
    % group) must rotate through every reliability class of a PAM axis
    s = max(nbpsc / 2, 1);
    cls = mod(mod(j(1:16) - 1, nbpsc), s);
    assert(numel(unique(cls)) == s, 'bits not rotated across reliability classes');
    x = rand(ncbps * 3, 2);
    assert(isequal(deinterleave(interleave(x, ncbps, nbpsc), ncbps, nbpsc), x), ...
           'deinterleave is not the inverse');
end
% 802.11a BPSK: first permutation only, bit k -> 3*mod(k,16)+floor(k/16)
j = interleaver_index(48, 1) - 1;
k = (0:47)';
assert(isequal(j, 3 * mod(k, 16) + floor(k / 16)), 'BPSK interleaver mismatch');
end
