function [x, info] = phy_tx(psdu_bits, mcs, scr_state)
%PHY_TX  802.11a-style transmitter: preamble + DATA field samples.
%   psdu_bits  0/1 column vector, length a multiple of 8
%   mcs        struct from MCS_TABLE
%   scr_state  7-bit nonzero scrambler seed (default: all ones)
%
%   DATA field = SERVICE (16 zeros) + PSDU + 6 tail + pad, scrambled,
%   convolutionally encoded, punctured, interleaved, QAM-mapped, OFDM.
%   The SIGNAL field is not generated; the receiver is told the MCS and
%   length (see README limitations).
if nargin < 3
    scr_state = ones(7, 1);
end
psdu_bits = double(psdu_bits(:));
nbytes = numel(psdu_bits) / 8;
if nbytes ~= floor(nbytes)
    error('phy_tx:len', 'PSDU must be a whole number of bytes');
end
nsym = phy_nsym(mcs, nbytes);
ndata = nsym * mcs.ndbps;
npad = ndata - (16 + numel(psdu_bits) + 6);

data = [zeros(16, 1); psdu_bits; zeros(6, 1); zeros(npad, 1)];
scr = scrambler(data, scr_state);
tail = 16 + numel(psdu_bits) + (1:6);
scr(tail) = 0;                               % return encoder to state 0

coded = puncture(conv_encode(scr), mcs.rate);
inter = interleave(coded, mcs.ncbps, mcs.nbpsc);
syms = qam_map(inter, mcs.nbpsc);
x = [preamble(); ofdm_mod(syms, 1)];

info.nsym = nsym;
info.ndata = ndata;
info.scrambled = scr;
info.coded = coded;
info.syms = syms;
end
