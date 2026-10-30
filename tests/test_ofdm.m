function test_ofdm()
p = ofdm_params();
assert(numel(p.data_k) == 48 && numel(p.pilot_k) == 4, 'subcarrier count');
assert(~any(p.used_k == 0), 'DC must be unused');
assert(all(abs(p.pilot_polarity) == 1) && numel(p.pilot_polarity) == 127, 'pilot polarity');
% p_0..p_7 from the standard: 1,1,1,1,-1,-1,-1,1
assert(isequal(p.pilot_polarity(1:8)', [1 1 1 1 -1 -1 -1 1]), 'pilot polarity prefix');

[pre, stf_f, ltf_f] = preamble();
assert(numel(pre) == 320, 'preamble length');
assert(nnz(stf_f) == 12 && nnz(ltf_f) == 52 && ltf_f(1) == 0, 'training symbols');
assert(max(abs(pre(1:16) - pre(17:32))) < 1e-12, 'STF not periodic in 16');
assert(abs(mean(abs(pre(193:256)).^2) - 1) < 1e-12, 'LTF power not 1');

% round trip
dl = qam_map(double(rand(48 * 4 * 200, 1) > 0.5), 4);
assert(abs(mean(abs(ofdm_mod(dl, 1)).^2) - 1) < 0.05, 'TX power not ~1');
d = dl(1:48 * 5);
x = ofdm_mod(d, 1);
assert(numel(x) == 80 * 5, 'symbol length');
Y = ofdm_demod(x, 5);
assert(max(max(abs(Y(p.data_bins, :) - reshape(d, 48, 5)))) < 1e-12, 'round trip');

% multipath shorter than the CP is a per-subcarrier multiplication
h = [0.8; 0.3 - 0.4i; 0; 0.2i; 0.1];
y = filter(h, 1, x);
Y = ofdm_demod(y, 5);
H = fft([h; zeros(59, 1)]);
Z = Y(p.data_bins, :) ./ repmat(H(p.data_bins), 1, 5);
assert(max(max(abs(Z - reshape(d, 48, 5)))) < 1e-10, 'CP did not absorb multipath');
end
