function [llr, info] = phy_rx_front(r, mcs, psdu_bytes, opts)
%PHY_RX_FRONT  Receiver front end: sync, channel estimate, equalise, demap.
%   llr = PHY_RX_FRONT(r, mcs, psdu_bytes) returns the depunctured rate-1/2
%   LLR stream (2 * nsym * ndbps x 1) ready for VITERBI_DECODE.
%
%   opts fields (optional):
%     search    samples to search for the packet start (default 400)
%     backoff   FFT window advance into the CP in samples (default 4)
%     genie     struct with fields start, h, n0 and optionally cfo (cycles
%               per sample), e.g. the second output of CHANNEL_TDL, to
%               bypass sync and estimation (isolates those stages)
%     pilot_track  common phase tracking from pilots (default true)
if nargin < 4
    opts = struct();
end
if ~isfield(opts, 'search'), opts.search = 400; end
if ~isfield(opts, 'backoff'), opts.backoff = 4; end
if ~isfield(opts, 'pilot_track'), opts.pilot_track = true; end
if ~isfield(opts, 'genie'), opts.genie = []; end

p = ofdm_params();
[~, ~, ltf_f] = preamble();
r = r(:);
nsym = phy_nsym(mcs, psdu_bytes);
n = (0:numel(r)-1)';

if isempty(opts.genie)
    % 1) coarse CFO on the STF, 2) LTF timing + fine CFO on corrected signal
    cfo_c = sync_coarse(r, opts.search);
    r = r .* exp(-1i * 2 * pi * cfo_c * n);
    [ltf_start, cfo_f] = sync_fine(r, opts.search + 160, opts.backoff);
    r = r .* exp(-1i * 2 * pi * cfo_f * n);
    cfo = cfo_c + cfo_f;
else
    ltf_start = opts.genie.start + 192 - opts.backoff;
    cfo = 0;
    if isfield(opts.genie, 'cfo')
        cfo = opts.genie.cfo;
        r = r .* exp(-1i * 2 * pi * cfo * n);
    end
end

data_start = ltf_start + 128;
need = data_start + nsym * (p.nfft + p.ncp) - 1;
if need > numel(r)
    r = [r; zeros(need - numel(r), 1)];  % timing landed late: zero-fill
end

% Channel and noise estimate from the two LTF symbols
Y1 = fft(r(ltf_start:ltf_start+63)) / p.tx_scale;
Y2 = fft(r(ltf_start+64:ltf_start+127)) / p.tx_scale;
u = p.used_bins;
if isempty(opts.genie)
    H = zeros(64, 1);
    H(u) = (Y1(u) + Y2(u)) / 2 ./ ltf_f(u);
    nv = max(mean(abs(Y1(u) - Y2(u)).^2) / 2, 1e-12);
else
    Hfull = fft([opts.genie.h(:); zeros(64 - numel(opts.genie.h), 1)]);
    % account for the window advance (circular shift by backoff samples)
    H = Hfull .* exp(-1i * 2 * pi * (0:63)' * opts.backoff / 64);
    nv = max(opts.genie.n0 / p.tx_scale^2 * 64, 1e-12);
end

Y = ofdm_demod(r(data_start:end), nsym);
llr_c = zeros(mcs.ncbps, nsym);
pol = p.pilot_polarity(mod(1 + (0:nsym-1), 127) + 1);
phases = zeros(1, nsym);
for s = 1:nsym
    if opts.pilot_track
        ref = p.pilot_vals(:) * pol(s) .* H(p.pilot_bins);
        phases(s) = angle(sum(conj(ref) .* Y(p.pilot_bins, s)));
    end
    Hd = H(p.data_bins) * exp(1i * phases(s));
    z = Y(p.data_bins, s) ./ Hd;
    llr_c(:, s) = qam_demap_llr(z, mcs.nbpsc, nv ./ abs(Hd).^2);
end

llr_d = deinterleave(llr_c(:), mcs.ncbps, mcs.nbpsc);
llr = depuncture(llr_d, mcs.rate, 2 * nsym * mcs.ndbps);
% clip so a deep fade cannot produce huge metrics
llr = max(min(llr, 50), -50);

info.ltf_start = ltf_start;
info.cfo = cfo;
info.noise_var = nv;
info.H = H;
info.phases = phases;
info.nsym = nsym;
end
