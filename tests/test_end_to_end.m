function test_end_to_end()
% Every MCS decodes error-free at high SNR through multipath + CFO + offset,
% with full blind synchronisation and estimation.
for m = 1:mcs_table()
    mcs = mcs_table(m);
    bits = double(rand(8 * 60, 1) > 0.5);
    x = phy_tx(bits, mcs, [1 0 1 1 0 0 1]');
    cfg = struct('snr_db', 35, 'rms_delay', 1.5, 'cfo_hz', 90e3, 'lead', 117);
    r = channel_tdl(x, cfg);
    llr = phy_rx_front(r, mcs, 60);
    rx = phy_rx_decode(llr, 60);
    assert(isequal(rx, bits), sprintf('MCS %d (%s) failed', m, mcs.name));
end

% genie path (perfect timing/channel) gives the same result
mcs = mcs_table(8);
bits = double(rand(8 * 60, 1) > 0.5);
x = phy_tx(bits, mcs);
[r, ch] = channel_tdl(x, struct('snr_db', 35, 'rms_delay', 1, 'lead', 20));
g.start = ch.start; g.h = ch.h; g.n0 = ch.n0;
llr = phy_rx_front(r, mcs, 60, struct('genie', g));
assert(isequal(phy_rx_decode(llr, 60), bits), 'genie receiver failed');

% residual CFO after sync is removed by pilot-based phase tracking
bits = double(rand(8 * 400, 1) > 0.5);
x = phy_tx(bits, mcs);
[r, ch] = channel_tdl(x, struct('snr_db', 35, 'cfo_hz', 3e3, 'lead', 10));
g.start = ch.start; g.h = ch.h; g.n0 = ch.n0;
on = phy_rx_decode(phy_rx_front(r, mcs, 400, struct('genie', g)), 400);
off = phy_rx_decode(phy_rx_front(r, mcs, 400, struct('genie', g, 'pilot_track', false)), 400);
assert(isequal(on, bits), 'pilot tracking did not fix residual CFO');
assert(~isequal(off, bits), 'test is not sensitive to pilot tracking');

% regression: scrambled pad bits after the tail leave the encoder outside
% state 0. Tracing back from state 0 at the end of the stream (instead of
% at the tail) corrupts the last PSDU bits under mild noise.
mcs = mcs_table(3);
nbad = 0;
for t = 1:60
    bits = double(rand(8 * 50, 1) > 0.5);
    [~, info] = phy_tx(bits, mcs);
    llr = 4 * ((1 - 2 * info.coded) + 0.45 * randn(size(info.coded)));
    llr = depuncture(llr, mcs.rate, 2 * info.ndata);
    nbad = nbad + ~isequal(phy_rx_decode(llr, 50), bits);
end
assert(nbad == 0, sprintf('%d of 60 packets lost near the tail', nbad));

% packets per symbol bookkeeping
assert(phy_nsym(mcs_table(1), 100) == ceil((16 + 800 + 6) / 24), 'nsym');
end
