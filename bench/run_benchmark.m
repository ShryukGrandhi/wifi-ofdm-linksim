function results = run_benchmark(mode)
%RUN_BENCHMARK  Measure accuracy, link performance and speed of the PHY.
%   RUN_BENCHMARK('full')  writes bench/results.md (takes minutes)
%   RUN_BENCHMARK('quick') same sections with far fewer trials (CI smoke run)
%
%   Sections
%   1. Uncoded BER of the mapper/demapper vs closed-form AWGN theory
%   2. SNR needed for PER <= 10 % per MCS: AWGN and multipath, blind
%      receiver; multipath also with a genie receiver (true timing, CFO,
%      channel) to isolate the synchronisation/estimation loss
%   3. Synchronisation accuracy (CFO RMSE, timing) vs SNR in multipath
%   4. Speed: batched vs per-packet Viterbi, and full receiver time/packet
if nargin < 1
    mode = 'quick';
end
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'src'));
full = strcmp(mode, 'full');
rng(2026);

if full
    cfg = struct('ber_bits', 2e6, 'pkts', 200, 'sync_trials', 400, ...
                 'psdu', 100, 'speed_pkts', 64, 'speed_bytes', 500);
else
    cfg = struct('ber_bits', 1e5, 'pkts', 25, 'sync_trials', 40, ...
                 'psdu', 100, 'speed_pkts', 16, 'speed_bytes', 200);
end

out = {};
out{end+1} = sprintf('# Benchmark results (%s mode)\n', mode);
out{end+1} = sprintf('Produced by `bench/run_benchmark.m` with %s.\n', runtime_name());
out{end+1} = sprintf('SNR is the average signal-to-noise ratio per time-domain sample at 20 MS/s; the per-subcarrier SNR is 10*log10(64/52) = %.2f dB higher.\n', 10*log10(64/52));

%% 1. Uncoded BER vs theory
t0 = tic;
out{end+1} = sprintf('## 1. Uncoded BER vs theory (AWGN, %g bits per point)\n', cfg.ber_bits);
out{end+1} = '| Modulation | Es/N0 (dB) | Measured BER | Theory BER | Ratio |';
out{end+1} = '|---|---|---|---|---|';
mods = {1, 'BPSK', [4 6 8]; 2, 'QPSK', [7 9 11]; 4, '16-QAM', [13 15 17]; 6, '64-QAM', [19 21 23]};
worst = 0;
for m = 1:size(mods, 1)
    nbpsc = mods{m, 1};
    for es = mods{m, 3}
        nb = floor(cfg.ber_bits / nbpsc) * nbpsc;
        bits = double(rand(nb, 1) > 0.5);
        s = qam_map(bits, nbpsc);
        n0 = 10^(-es / 10);
        y = s + sqrt(n0 / 2) * (randn(size(s)) + 1i * randn(size(s)));
        ber = mean(double(qam_demap_llr(y, nbpsc, n0) < 0) ~= bits);
        th = ber_theory_awgn(nbpsc, es);
        worst = max(worst, abs(ber / th - 1));
        out{end+1} = sprintf('| %s | %d | %.3e | %.3e | %.3f |', mods{m, 2}, es, ber, th, ber / th);
    end
end
results.ber_worst_rel_err = worst;
out{end+1} = sprintf('\nLargest relative deviation from theory: %.1f %%. Section time %.1f s.\n', 100 * worst, toc(t0));

%% 2. Required SNR per MCS
t0 = tic;
awgn = struct('rms_delay', 0, 'lead_max', 100, 'cfo_max_hz', 100e3);
tdl = struct('rms_delay', 2, 'lead_max', 100, 'cfo_max_hz', 100e3);
out{end+1} = sprintf('## 2. SNR (dB) for PER <= 10 %%, %d-byte PSDU, %d packets per SNR point, 1 dB grid\n', cfg.psdu, cfg.pkts);
out{end+1} = 'Blind receiver: STF coarse CFO, LTF timing and fine CFO, LS channel estimate, pilot phase tracking. Each packet has a random start offset (0-100 samples) and CFO (uniform +-100 kHz). Multipath: Rayleigh block fading, exponential profile, RMS delay 2 samples (100 ns), 16 taps. Genie: true timing, CFO, channel and noise power.';
out{end+1} = '';
out{end+1} = '| MCS | Mode | Rate (Mb/s) | AWGN blind | Multipath blind | Multipath genie | Estimation loss (dB) |';
out{end+1} = '|---|---|---|---|---|---|---|';
nm = mcs_table();
req = zeros(nm, 3);
start = [0 0 0];
for m = 1:nm
    mcs = mcs_table(m);
    [req(m, 1), start(1)] = required_snr(m, awgn, struct(), cfg, start(1));
    [req(m, 2), start(2)] = required_snr(m, tdl, struct(), cfg, start(2));
    [req(m, 3), start(3)] = required_snr(m, tdl, struct('genie_rx', true), cfg, start(3));
    out{end+1} = sprintf('| %d | %s | %d | %s | %s | %s | %s |', m, mcs.name, mcs.mbps, ...
        fmt_snr(req(m, 1)), fmt_snr(req(m, 2)), fmt_snr(req(m, 3)), fmt_loss(req(m, 2) - req(m, 3)));
    fprintf('  MCS %d done (%.0f s)\n', m, toc(t0));
end
results.required_snr = req;
out{end+1} = sprintf('\nSection time %.1f s.\n', toc(t0));

%% 3. Sync accuracy
t0 = tic;
out{end+1} = sprintf('## 3. Synchronisation accuracy (multipath as above, %d packets per SNR)\n', cfg.sync_trials);
out{end+1} = 'Timing is counted correct when the chosen FFT window start lies inside the cyclic prefix after the channel delay spread (a window that causes no inter-symbol interference). The delay spread is taken as the shortest tap prefix holding 99 % of the realised channel energy.';
out{end+1} = '';
out{end+1} = '| SNR (dB) | CFO RMSE (Hz) | CFO RMSE (ppm @ 5.2 GHz) | Timing in ISI-free window |';
out{end+1} = '|---|---|---|---|';
mcs = mcs_table(1);
x = phy_tx(double(rand(8 * 20, 1) > 0.5), mcs);
for snr = [0 5 10 20]
    e = zeros(cfg.sync_trials, 1);
    ok = 0;
    for t = 1:cfg.sync_trials
        c = tdl;
        c.snr_db = snr;
        c.lead = floor(rand * 101);
        c.cfo_hz = (2 * rand - 1) * 100e3;
        c = rmfield(c, {'lead_max', 'cfo_max_hz'});
        [r, ch] = channel_tdl(x, c);
        [~, info] = phy_rx_front(r, mcs, 20);
        e(t) = (info.cfo - ch.cfo) * 20e6;
        true_ltf = ch.start + 192;
        cum = cumsum(abs(ch.h).^2) / sum(abs(ch.h).^2);
        L = find(cum >= 0.99, 1);
        % window may start up to (16 - (L-1)) samples before the true symbol
        ok = ok + (info.ltf_start <= true_ltf && info.ltf_start >= true_ltf - (16 - (L - 1)));
    end
    rmse = sqrt(mean(e.^2));
    out{end+1} = sprintf('| %d | %.0f | %.2f | %.1f %% |', snr, rmse, rmse / 5.2e3, 100 * ok / cfg.sync_trials);
end
out{end+1} = sprintf('\nSection time %.1f s.\n', toc(t0));

%% 4. Speed
out{end+1} = sprintf('## 4. Speed (%d packets of %d bytes, 64-QAM 3/4)\n', cfg.speed_pkts, cfg.speed_bytes);
mcs = mcs_table(8);
P = cfg.speed_pkts;
nsym = phy_nsym(mcs, cfg.speed_bytes);
llr = zeros(2 * nsym * mcs.ndbps, P);
tic_front = 0;
for k = 1:P
    x = phy_tx(double(rand(8 * cfg.speed_bytes, 1) > 0.5), mcs);
    r = channel_tdl(x, struct('snr_db', 30, 'rms_delay', 2, 'lead', 50, 'cfo_hz', 40e3));
    t1 = tic;
    llr(:, k) = phy_rx_front(r, mcs, cfg.speed_bytes);
    tic_front = tic_front + toc(t1);
end
info_bits = 16 + 8 * cfg.speed_bytes + 6;
L = llr(1:2*info_bits, :);
viterbi_decode(L(:, 1));                         % warm-up (trellis cache)
t1 = tic;
for k = 1:P
    viterbi_decode(L(:, k));
end
t_single = toc(t1);
t1 = tic;
viterbi_decode(L);
t_batch = toc(t1);
t1 = tic;
phy_rx_decode(llr, cfg.speed_bytes);
t_dec = toc(t1);
nbits = info_bits * P;
out{end+1} = '| Stage | Time | Throughput |';
out{end+1} = '|---|---|---|';
out{end+1} = sprintf('| Viterbi, one packet per call | %.3f s | %.2f Mbit/s decoded |', t_single, nbits / t_single / 1e6);
out{end+1} = sprintf('| Viterbi, all %d packets in one batched call | %.3f s | %.2f Mbit/s decoded |', P, t_batch, nbits / t_batch / 1e6);
out{end+1} = sprintf('| Receiver front end (sync, estimation, demap) | %.2f ms/packet | %.2f Mbit/s of PSDU |', 1e3 * tic_front / P, 8 * cfg.speed_bytes * P / tic_front / 1e6);
out{end+1} = sprintf('| Full receive chain (front end + batched decode) | %.2f ms/packet | %.2f Mbit/s of PSDU |', 1e3 * (tic_front + t_dec) / P, 8 * cfg.speed_bytes * P / (tic_front + t_dec) / 1e6);
out{end+1} = sprintf('\nBatched Viterbi speed-up over per-packet calls: %.1fx. Wall-clock numbers depend on the machine; single-threaded interpreter.\n', t_single / t_batch);
results.viterbi_speedup = t_single / t_batch;

text = sprintf('%s\n', out{:});
fprintf('%s', text);
if full
    fid = fopen(fullfile(here, 'results.md'), 'w');
    fprintf(fid, '%s', text);
    fclose(fid);
end
end

function [snr_req, next_start] = required_snr(m, chan, opts, cfg, start)
% Sweep upward in 1 dB steps until PER <= 0.1. Returns NaN if not reached.
snr_req = NaN;
next_start = start;
for snr = start:1:45
    res = link_sim(m, snr, chan, cfg.pkts, cfg.psdu, opts);
    if res.per <= 0.1
        snr_req = snr;
        next_start = max(snr - 3, 0);
        return;
    end
end
end

function s = fmt_snr(v)
if isnan(v), s = '>45'; else, s = sprintf('%d', v); end
end

function s = fmt_loss(v)
if isnan(v), s = 'n/a'; else, s = sprintf('%d', v); end
end

function s = runtime_name()
if exist('OCTAVE_VERSION', 'builtin')
    s = ['GNU Octave ' OCTAVE_VERSION];
else
    s = ['MATLAB ' version];
end
end
