function sym = qam_map(bits, nbpsc)
%QAM_MAP  Gray-mapped BPSK/QPSK/16-QAM/64-QAM with unit average energy.
%   The first nbpsc/2 bits of each group select the I level, the rest the
%   Q level (802.11a ordering). BPSK maps 0 -> -1, 1 -> +1.
bits = double(bits(:));
if mod(numel(bits), nbpsc) ~= 0
    error('qam_map:len', 'bit count not a multiple of %d', nbpsc);
end
k = qam_norm(nbpsc);
B = reshape(bits, nbpsc, [])';
if nbpsc == 1
    sym = k * (2 * B - 1);
    return;
end
h = nbpsc / 2;
sym = k * (pam_bits_to_level(B(:, 1:h)) + 1i * pam_bits_to_level(B(:, h+1:end)));
end

function v = pam_bits_to_level(b)
m = size(b, 2);
[levels, labels] = pam_gray_levels(m);
code = b * (2 .^ (m-1:-1:0))';
lut = zeros(2^m, 1);
lut(labels * (2 .^ (m-1:-1:0))' + 1) = levels;
v = lut(code + 1);
end
