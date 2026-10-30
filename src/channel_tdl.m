function [r, ch] = channel_tdl(x, cfg)
%CHANNEL_TDL  Block-fading tapped-delay-line channel with CFO and AWGN.
%   cfg fields (all optional):
%     snr_db       average SNR per time-domain sample (default 30)
%     rms_delay    RMS delay spread in samples (0 = flat, no fading; default 0)
%     ntaps        tap count for the exponential profile (default 10*rms+1, max 16)
%     cfo_hz       carrier frequency offset in Hz (default 0)
%     lead         samples of noise before the packet (default 0)
%     trail        samples of noise after the packet (default 64)
%     h            explicit impulse response (overrides rms_delay)
%   Tap gains are complex Gaussian (Rayleigh) with an exponential power delay
%   profile normalised to unit total average power, constant over a packet.
p = ofdm_params();
cfg = fill_defaults(cfg);
x = x(:);

if isfield(cfg, 'h') && ~isempty(cfg.h)
    h = cfg.h(:);
elseif cfg.rms_delay <= 0
    h = 1;
else
    if isempty(cfg.ntaps)
        L = min(16, ceil(10 * cfg.rms_delay) + 1);
    else
        L = cfg.ntaps;
    end
    pdp = exp(-(0:L-1)' / cfg.rms_delay);
    pdp = pdp / sum(pdp);
    h = sqrt(pdp / 2) .* (randn(L, 1) + 1i * randn(L, 1));
end

s = [zeros(cfg.lead, 1); x; zeros(cfg.trail, 1)];
y = filter(h, 1, s);
n = (0:numel(y)-1)';
y = y .* exp(1i * 2 * pi * cfg.cfo_hz / p.fs * n);
n0 = 10^(-cfg.snr_db / 10);
r = y + sqrt(n0 / 2) * (randn(size(y)) + 1i * randn(size(y)));

ch.h = h;
ch.n0 = n0;
ch.start = cfg.lead + 1;
end

function cfg = fill_defaults(cfg)
d = struct('snr_db', 30, 'rms_delay', 0, 'ntaps', [], 'cfo_hz', 0, ...
           'lead', 0, 'trail', 64);
f = fieldnames(d);
for i = 1:numel(f)
    if ~isfield(cfg, f{i})
        cfg.(f{i}) = d.(f{i});
    end
end
end
