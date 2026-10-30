function llr = qam_demap_llr(y, nbpsc, nvar)
%QAM_DEMAP_LLR  Max-log LLRs for Gray QAM, positive = bit 0 more likely.
%   y     received (equalized) symbols, column vector
%   nbpsc bits per symbol (1, 2, 4, 6)
%   nvar  complex noise variance per symbol after equalization; scalar or
%         same size as y (per-subcarrier, e.g. N0/|H|^2)
%   Returns a column of numel(y)*nbpsc LLRs in transmit bit order.
%
%   Square QAM with Gray labels separates into two PAM axes, so the minimum
%   distance search runs over sqrt(M) levels per axis, not M points.
y = y(:);
if isscalar(nvar)
    nvar = nvar * ones(size(y));
end
nvar = nvar(:);
k = qam_norm(nbpsc);
if nbpsc == 1
    L = pam_llr(real(y) / k, 1, nvar / k^2);
    llr = L;
    return;
end
h = nbpsc / 2;
LI = pam_llr(real(y) / k, h, nvar / k^2);
LQ = pam_llr(imag(y) / k, h, nvar / k^2);
llr = reshape([LI LQ]', [], 1);
end

function L = pam_llr(r, m, nv)
% r: N x 1 normalized amplitudes. L: N x m LLRs, m = bits on this axis.
[levels, labels] = pam_gray_levels(m);
D = bsxfun(@minus, r, levels') .^ 2;       % N x M squared distances
L = zeros(numel(r), m);
for b = 1:m
    d0 = min(D(:, labels(:, b) == 0), [], 2);
    d1 = min(D(:, labels(:, b) == 1), [], 2);
    L(:, b) = (d1 - d0) ./ nv;
end
end
