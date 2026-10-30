function Y = ofdm_demod(r, nsym)
%OFDM_DEMOD  Strip cyclic prefixes and FFT. R starts at the first CP sample.
%   Returns a 64 x nsym matrix of subcarrier values (same scale as TX).
p = ofdm_params();
len = (p.nfft + p.ncp) * nsym;
if numel(r) < len
    error('ofdm_demod:len', 'need %d samples, have %d', len, numel(r));
end
blk = reshape(r(1:len), p.nfft + p.ncp, nsym);
Y = fft(blk(p.ncp+1:end, :)) / p.tx_scale;
end
