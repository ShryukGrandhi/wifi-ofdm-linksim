function test_sync()
% CFO and timing estimates on a full packet with random offset.
mcs = mcs_table(3);
x = phy_tx(double(rand(400, 1) > 0.5), mcs);
fs = 20e6;
for cfo_hz = [-200e3 -37e3 0 58e3 230e3]
    lead = 50 + floor(rand * 150);
    r = channel_tdl(x, struct('snr_db', 20, 'cfo_hz', cfo_hz, 'lead', lead));
    [cfo_c, ~] = sync_coarse(r, 400);
    assert(abs(cfo_c * fs - cfo_hz) < 15e3, sprintf('coarse CFO off at %g Hz', cfo_hz));
    n = (0:numel(r)-1)';
    rc = r .* exp(-1i * 2 * pi * cfo_c * n);
    [ls, cfo_f] = sync_fine(rc, 560, 0);
    assert(ls == lead + 193, sprintf('LTF timing %d, expected %d', ls, lead + 193));
    assert(abs((cfo_c + cfo_f) * fs - cfo_hz) < 2e3, 'fine CFO error > 2 kHz');
end
end
