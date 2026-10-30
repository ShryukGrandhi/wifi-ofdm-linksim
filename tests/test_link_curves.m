function test_link_curves()
% PER must fall as SNR rises, and coding must beat uncoded transmission.
res = link_sim(3, [2 6 12], struct('rms_delay', 0, 'lead_max', 40), 40, 50);
assert(res.per(1) > res.per(3), 'PER did not fall with SNR');
assert(res.per(3) == 0, sprintf('QPSK 1/2 failing at 12 dB: PER %.2f', res.per(3)));
assert(all(diff(res.ber) <= 0), 'BER not monotone');

% higher MCS needs more SNR: at 12 dB 64-QAM 3/4 must be worse than QPSK 1/2
r8 = link_sim(8, 12, struct('rms_delay', 0), 20, 50);
assert(r8.per > res.per(3), '64QAM 3/4 should fail at 12 dB');

% coded QPSK 1/2 at 6 dB SNR beats uncoded QPSK at the same subcarrier SNR
esn0 = 6 + 10 * log10(64 / 52);
assert(res.ber(2) < ber_theory_awgn(2, esn0), 'coding gain missing');
end
