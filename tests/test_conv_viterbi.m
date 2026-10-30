function test_conv_viterbi()
% Encoder impulse response equals the generator polynomials (133, 171 octal).
c = conv_encode([1; zeros(6, 1)]);
A = c(1:2:end)'; B = c(2:2:end)';
assert(isequal(A, [1 0 1 1 0 1 1]), 'g0 impulse response wrong');
assert(isequal(B, [1 1 1 1 0 0 1]), 'g1 impulse response wrong');

% Linearity over GF(2)
u1 = double(rand(100, 1) > 0.5); u2 = double(rand(100, 1) > 0.5);
assert(isequal(conv_encode(xor(u1, u2)), double(xor(conv_encode(u1), conv_encode(u2)))), ...
       'encoder is not linear');

% Noise-free decode at every code rate
for rate = {[1 2], [2 3], [3 4]}
    r = rate{1};
    u = [double(rand(300, 1) > 0.5); zeros(6, 1)];
    tx = puncture(conv_encode(u), r);
    llr = depuncture(1 - 2 * tx, r, 2 * numel(u));
    assert(isequal(viterbi_decode(llr), u), sprintf('rate %d/%d decode failed', r));
end

% Hard-decision: free distance 10 => any 4 channel errors are corrected
% when isolated; place them far apart over several blocks.
u = [double(rand(400, 1) > 0.5); zeros(6, 1)];
cw = conv_encode(u);
for trial = 1:20
    e = zeros(size(cw));
    pos = randperm(numel(cw), 4);
    e(pos) = 1;
    llr = 1 - 2 * xor(cw, e);
    assert(isequal(viterbi_decode(llr), u), 'failed to correct 4 errors');
end

% Batched decoding equals per-column decoding
U = double(rand(206, 5) > 0.5); U(end-5:end, :) = 0;
L = zeros(412, 5);
for k = 1:5
    L(:, k) = (1 - 2 * conv_encode(U(:, k))) + 0.9 * randn(412, 1);
end
Db = viterbi_decode(L);
for k = 1:5
    assert(isequal(Db(:, k), viterbi_decode(L(:, k))), 'batch mismatch');
end

% Soft decoding beats hard decoding at the same noise level
u = [double(rand(3000, 1) > 0.5); zeros(6, 1)];
cw = conv_encode(u);
y = (1 - 2 * cw) + 0.85 * randn(size(cw));
e_soft = sum(viterbi_decode(y) ~= u);
e_hard = sum(viterbi_decode(sign(y)) ~= u);
assert(e_soft < e_hard, sprintf('soft (%d) not better than hard (%d)', e_soft, e_hard));

% Unterminated traceback still decodes a clean codeword
u = double(rand(50, 1) > 0.5);
assert(isequal(viterbi_decode(1 - 2 * conv_encode(u), false), u), 'unterminated decode');
end
