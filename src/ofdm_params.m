function p = ofdm_params()
%OFDM_PARAMS  802.11a 20 MHz numerology and subcarrier allocation.
%   Subcarrier indices run -26..26 (DC unused). FFT bin = mod(k, 64) + 1.
persistent cached;
if ~isempty(cached)
    p = cached;
    return;
end
p.nfft = 64;
p.ncp = 16;
p.fs = 20e6;
p.pilot_k = [-21 -7 7 21];
p.pilot_vals = [1 1 1 -1];
used = [-26:-1, 1:26];
p.data_k = setdiff(used, p.pilot_k);
p.used_k = used;
p.data_bins = mod(p.data_k, 64) + 1;
p.pilot_bins = mod(p.pilot_k, 64) + 1;
p.used_bins = mod(used, 64) + 1;
p.nused = numel(used);
% time-domain scaling so a symbol of unit-energy subcarriers has unit
% average sample power
p.tx_scale = p.nfft / sqrt(p.nused);
p.pilot_polarity = pilot_polarity();
cached = p;
end

function pol = pilot_polarity()
% 127-element sequence p_n: scrambler output for all-ones seed, 0 -> +1, 1 -> -1
seq = scrambler(zeros(127, 1), ones(7, 1));
pol = 1 - 2 * seq;
end
