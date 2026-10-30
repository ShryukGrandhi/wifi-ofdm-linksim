function test_qam()
for nbpsc = [1 2 4 6]
    M = 2^nbpsc;
    % all labels, natural order
    lab = zeros(M, nbpsc);
    for b = 1:nbpsc
        lab(:, b) = bitget((0:M-1)', nbpsc - b + 1);
    end
    s = qam_map(reshape(lab', [], 1), nbpsc);
    assert(abs(mean(abs(s).^2) - 1) < 1e-12, 'average energy is not 1');
    assert(numel(unique(round(s * 1e9))) == M, 'constellation points not distinct');

    % Gray property: nearest neighbours differ in exactly one bit
    D = abs(bsxfun(@minus, s, s.'));
    D(1:M+1:end) = inf;
    dmin = min(D(:));
    [a, b] = find(abs(D - dmin) < 1e-9);
    hd = sum(lab(a, :) ~= lab(b, :), 2);
    assert(all(hd == 1), 'mapping is not Gray');

    % noiseless demap gives correct hard decisions with the right sign
    bits = double(rand(nbpsc * 200, 1) > 0.5);
    llr = qam_demap_llr(qam_map(bits, nbpsc), nbpsc, 0.1);
    assert(isequal(double(llr < 0), bits), 'demapper hard decision wrong');
end
% 802.11a 16-QAM table: b0b1 = 00,01,11,10 -> -3,-1,1,3
s = qam_map([0 0 0 0, 0 1 0 0, 1 1 0 0, 1 0 0 0]', 4) * sqrt(10);
assert(max(abs(real(s) - [-3; -1; 1; 3])) < 1e-12, '16-QAM I levels wrong');

% LLR magnitude scales as 1/nvar
y = qam_map([0; 1], 2);
assert(max(abs(qam_demap_llr(y, 2, 0.5) - 2 * qam_demap_llr(y, 2, 1))) < 1e-12, ...
       'LLR does not scale with noise variance');
end
