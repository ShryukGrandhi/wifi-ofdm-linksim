function psdu = phy_rx_decode(llr, psdu_bytes)
%PHY_RX_DECODE  Viterbi-decode, descramble and extract PSDUs.
%   LLR is a matrix whose columns are packets of the same MCS and length
%   (output of PHY_RX_FRONT). Returns 8*psdu_bytes x P bits.
%
%   The encoder is in state 0 right after the 6 tail bits, but the scrambled
%   pad bits that follow drive it elsewhere. The code is causal, so the
%   coded bits after the tail carry no information about the PSDU: they are
%   dropped and the trellis is traced back from state 0 at the tail.
nb = 8 * psdu_bytes;
nterm = 16 + nb + 6;
dec = viterbi_decode(llr(1:2*nterm, :), true);
P = size(dec, 2);
psdu = zeros(nb, P);
for c = 1:P
    st = scrambler_seed_from_service(dec(1:7, c));
    d = scrambler(dec(8:16+nb, c), st);
    psdu(:, c) = d(10:end);       % bits 17.. of the DATA field
end
end
