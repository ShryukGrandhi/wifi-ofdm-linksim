function res = link_sim(mcs_idx, snr_db, chan, npkts, psdu_bytes, opts)
%LINK_SIM  Monte Carlo packet/bit error rate of the full TX -> channel -> RX chain.
%   res = LINK_SIM(mcs_idx, snr_db, chan, npkts, psdu_bytes)
%     mcs_idx    1..8 (see MCS_TABLE)
%     snr_db     vector of SNRs (dB, per time-domain sample)
%     chan       struct passed to CHANNEL_TDL (snr_db is overwritten);
%                lead is randomised per packet if chan.lead_max is set,
%                CFO is uniform in +-chan.cfo_max_hz if that is set
%     npkts      packets per SNR point
%     psdu_bytes payload size
%     opts       passed to PHY_RX_FRONT; opts.genie_rx = true gives the
%                receiver the true timing, channel and noise power
%   res fields: snr_db, per, ber, npkts, bit_errors, pkt_errors
%
%   Each packet gets a fresh random payload, scrambler seed, fading
%   realisation and noise. Front-end processing is per packet; all packets
%   at one SNR are then Viterbi-decoded together in one batched call.
if nargin < 6
    opts = struct();
end
mcs = mcs_table(mcs_idx);
nb = 8 * psdu_bytes;
res.snr_db = snr_db(:)';
res.per = zeros(size(res.snr_db));
res.ber = zeros(size(res.snr_db));
res.bit_errors = zeros(size(res.snr_db));
res.pkt_errors = zeros(size(res.snr_db));
res.npkts = npkts;

for i = 1:numel(snr_db)
    llr = zeros(2 * phy_nsym(mcs, psdu_bytes) * mcs.ndbps, npkts);
    tx = zeros(nb, npkts);
    for k = 1:npkts
        bits = double(rand(nb, 1) > 0.5);
        seed = zeros(7, 1);
        while ~any(seed)
            seed = double(rand(7, 1) > 0.5);
        end
        x = phy_tx(bits, mcs, seed);
        c = chan;
        c.snr_db = snr_db(i);
        if isfield(chan, 'lead_max')
            c.lead = floor(rand * (chan.lead_max + 1));
            c = rmfield(c, 'lead_max');
        end
        if isfield(chan, 'cfo_max_hz')
            c.cfo_hz = (2 * rand - 1) * chan.cfo_max_hz;
            c = rmfield(c, 'cfo_max_hz');
        end
        [r, ch] = channel_tdl(x, c);
        o = opts;
        if isfield(opts, 'genie_rx') && opts.genie_rx
            o.genie = ch;
        end
        llr(:, k) = phy_rx_front(r, mcs, psdu_bytes, o);
        tx(:, k) = bits;
    end
    rx = phy_rx_decode(llr, psdu_bytes);
    errs = sum(rx ~= tx, 1);
    res.bit_errors(i) = sum(errs);
    res.pkt_errors(i) = nnz(errs);
    res.ber(i) = sum(errs) / (nb * npkts);
    res.per(i) = nnz(errs) / npkts;
end
end
