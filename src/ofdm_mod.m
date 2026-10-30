function x = ofdm_mod(data_syms, first_symbol_index)
%OFDM_MOD  Map 48 data symbols per OFDM symbol, insert pilots, IFFT, add CP.
%   data_syms: 48*Nsym x 1 complex. first_symbol_index selects the pilot
%   polarity offset (802.11a: SIGNAL uses p_0, DATA starts at p_1).
%   Returns (64+16)*Nsym x 1 time-domain samples with unit average power.
if nargin < 2
    first_symbol_index = 1;
end
p = ofdm_params();
nsym = numel(data_syms) / 48;
if nsym ~= floor(nsym)
    error('ofdm_mod:len', 'need a multiple of 48 data symbols');
end
X = zeros(p.nfft, nsym);
X(p.data_bins, :) = reshape(data_syms, 48, nsym);
pol = p.pilot_polarity(mod(first_symbol_index + (0:nsym-1), 127) + 1);
X(p.pilot_bins, :) = p.pilot_vals(:) * pol(:)';
t = ifft(X) * p.tx_scale;
x = reshape([t(end-p.ncp+1:end, :); t], [], 1);
end
