function ber = ber_theory_awgn(nbpsc, esn0_db)
%BER_THEORY_AWGN  Uncoded Gray-coded square-QAM bit error rate in AWGN.
%   BPSK and QPSK are exact. 16/64-QAM use the standard nearest-neighbour
%   approximation (4/log2 M)(1 - 1/sqrt M) Q(sqrt(3 Es/N0 / (M-1))), which
%   is tight once BER is below ~1e-2.
es = 10.^(esn0_db / 10);
Q = @(x) 0.5 * erfc(x / sqrt(2));
switch nbpsc
    case 1
        ber = Q(sqrt(2 * es));
    case 2
        ber = Q(sqrt(es));
    case {4, 6}
        M = 2^nbpsc;
        ber = (4 / nbpsc) * (1 - 1 / sqrt(M)) * Q(sqrt(3 * es / (M - 1)));
    otherwise
        error('ber_theory_awgn:nbpsc', 'unsupported bits per symbol %d', nbpsc);
end
end
