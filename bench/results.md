# Benchmark results (full mode)

Produced by `bench/run_benchmark.m` with GNU Octave 8.4.0.

SNR is the average signal-to-noise ratio per time-domain sample at 20 MS/s; the per-subcarrier SNR is 10*log10(64/52) = 0.90 dB higher.

## 1. Uncoded BER vs theory (AWGN, 2e+06 bits per point)

| Modulation | Es/N0 (dB) | Measured BER | Theory BER | Ratio |
|---|---|---|---|---|
| BPSK | 4 | 1.250e-02 | 1.250e-02 | 1.000 |
| BPSK | 6 | 2.335e-03 | 2.388e-03 | 0.978 |
| BPSK | 8 | 1.885e-04 | 1.909e-04 | 0.987 |
| QPSK | 7 | 1.263e-02 | 1.259e-02 | 1.003 |
| QPSK | 9 | 2.420e-03 | 2.413e-03 | 1.003 |
| QPSK | 11 | 1.920e-04 | 1.940e-04 | 0.990 |
| 16-QAM | 13 | 1.701e-02 | 1.716e-02 | 0.992 |
| 16-QAM | 15 | 4.542e-03 | 4.465e-03 | 1.017 |
| 16-QAM | 17 | 5.795e-04 | 5.795e-04 | 1.000 |
| 64-QAM | 19 | 1.502e-02 | 1.511e-02 | 0.995 |
| 64-QAM | 21 | 4.186e-03 | 4.185e-03 | 1.000 |
| 64-QAM | 23 | 6.190e-04 | 5.989e-04 | 1.034 |

Largest relative deviation from theory: 3.4 %. Section time 0.9 s.

## 2. SNR (dB) for PER <= 10 %, 100-byte PSDU, 200 packets per SNR point, 1 dB grid

Blind receiver: STF coarse CFO, LTF timing and fine CFO, LS channel estimate, pilot phase tracking. Each packet has a random start offset (0-100 samples) and CFO (uniform +-100 kHz). Multipath: Rayleigh block fading, exponential profile, RMS delay 2 samples (100 ns), 16 taps. Genie: true timing, CFO, channel and noise power.

| MCS | Mode | Rate (Mb/s) | AWGN blind | Multipath blind | Multipath genie | Estimation loss (dB) |
|---|---|---|---|---|---|---|
| 1 | BPSK 1/2 | 6 | 3 | 7 | 5 | 2 |
| 2 | BPSK 3/4 | 9 | 4 | 11 | 9 | 2 |
| 3 | QPSK 1/2 | 12 | 6 | 10 | 8 | 2 |
| 4 | QPSK 3/4 | 18 | 8 | 13 | 12 | 1 |
| 5 | 16QAM 1/2 | 24 | 10 | 15 | 13 | 2 |
| 6 | 16QAM 3/4 | 36 | 14 | 19 | 17 | 2 |
| 7 | 64QAM 2/3 | 48 | 18 | 23 | 21 | 2 |
| 8 | 64QAM 3/4 | 54 | 19 | 24 | 22 | 2 |

Section time 218.9 s.

## 3. Synchronisation accuracy (multipath as above, 400 packets per SNR)

Timing is counted correct when the chosen FFT window start lies inside the cyclic prefix after the channel delay spread (a window that causes no inter-symbol interference). The delay spread is taken as the shortest tap prefix holding 99 % of the realised channel energy.

| SNR (dB) | CFO RMSE (Hz) | CFO RMSE (ppm @ 5.2 GHz) | Timing in ISI-free window |
|---|---|---|---|
| 0 | 47909 | 9.21 | 93.2 % |
| 5 | 4327 | 0.83 | 98.5 % |
| 10 | 2187 | 0.42 | 99.2 % |
| 20 | 854 | 0.16 | 98.5 % |

Section time 2.6 s.

## 4. Speed (64 packets of 500 bytes, 64-QAM 3/4)

| Stage | Time | Throughput |
|---|---|---|
| Viterbi, one packet per call | 4.725 s | 0.05 Mbit/s decoded |
| Viterbi, all 64 packets in one batched call | 0.268 s | 0.96 Mbit/s decoded |
| Receiver front end (sync, estimation, demap) | 6.56 ms/packet | 0.61 Mbit/s of PSDU |
| Full receive chain (front end + batched decode) | 12.41 ms/packet | 0.32 Mbit/s of PSDU |

Batched Viterbi speed-up over per-packet calls: 17.6x. Wall-clock numbers depend on the machine; single-threaded interpreter.

