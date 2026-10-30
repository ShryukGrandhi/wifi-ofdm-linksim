function [pre, stf_f, ltf_f, ltf_t] = preamble()
%PREAMBLE  802.11a PLCP preamble: 10 short + 2 long training symbols.
%   pre    320 x 1 time-domain preamble (160 STF + 32 GI2 + 2 x 64 LTF)
%   stf_f  64 x 1 short-training frequency-domain values (FFT bin order)
%   ltf_f  64 x 1 long-training values (FFT bin order)
%   ltf_t  64 x 1 one long-training symbol in time (scaled like data)
persistent c;
if ~isempty(c)
    pre = c.pre; stf_f = c.stf_f; ltf_f = c.ltf_f; ltf_t = c.ltf_t;
    return;
end
p = ofdm_params();
k = -26:26;

S = zeros(1, 53);
s_k   = [-24 -20 -16 -12 -8 -4 4 8 12 16 20 24];
s_val = [1+1i -1-1i 1+1i -1-1i -1-1i 1+1i -1-1i -1-1i 1+1i 1+1i 1+1i 1+1i];
S(s_k + 27) = sqrt(13/6) * s_val;

L = [1 1 -1 -1 1 1 -1 1 -1 1 1 1 1 1 1 -1 -1 1 1 -1 1 -1 1 1 1 1 ...
     0 ...
     1 -1 -1 1 1 -1 1 -1 1 -1 -1 -1 -1 -1 1 1 -1 -1 1 -1 1 -1 1 1 1 1];

stf_f = zeros(64, 1); stf_f(mod(k, 64) + 1) = S;
ltf_f = zeros(64, 1); ltf_f(mod(k, 64) + 1) = L;

stf_t = ifft(stf_f) * p.tx_scale;          % period-16 waveform
ltf_t = ifft(ltf_f) * p.tx_scale;
stf = repmat(stf_t(1:16), 10, 1);
ltf = [ltf_t(end-31:end); ltf_t; ltf_t];
pre = [stf; ltf];

c.pre = pre; c.stf_f = stf_f; c.ltf_f = ltf_f; c.ltf_t = ltf_t;
end
