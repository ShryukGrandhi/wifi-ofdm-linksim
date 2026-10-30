function test_uncoded_ber()
% Monte Carlo uncoded BER in AWGN must match theory within ~15 %.
cases = [1 7; 2 10; 4 16; 6 22];   % [nbpsc EsN0_dB]
n = 1e6;
for c = 1:size(cases, 1)
    nbpsc = cases(c, 1); es = cases(c, 2);
    nb = floor(n / nbpsc) * nbpsc;
    bits = double(rand(nb, 1) > 0.5);
    s = qam_map(bits, nbpsc);
    n0 = 10^(-es / 10);
    y = s + sqrt(n0 / 2) * (randn(size(s)) + 1i * randn(size(s)));
    ber = mean(double(qam_demap_llr(y, nbpsc, n0) < 0) ~= bits);
    th = ber_theory_awgn(nbpsc, es);
    assert(abs(ber / th - 1) < 0.15, ...
        sprintf('nbpsc=%d: BER %.3g vs theory %.3g', nbpsc, ber, th));
end
end
