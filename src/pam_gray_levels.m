function [levels, labels] = pam_gray_levels(m)
%PAM_GRAY_LEVELS  Gray-labelled PAM levels for M = 2^m points on one axis.
%   levels(i) is the amplitude whose bit label is labels(i, :) (MSB first).
%   For m = 2 this gives 00:-3, 01:-1, 11:+1, 10:+3 as in 802.11a.
M = 2^m;
idx = (0:M-1)';
levels = 2 * idx - (M - 1);
g = bitxor(idx, floor(idx / 2));            % binary -> Gray
labels = zeros(M, m);
for b = 1:m
    labels(:, b) = bitget(g, m - b + 1);
end
end
