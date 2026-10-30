function test_scrambler()
% Period, balance, self-inverse, and seed recovery from the SERVICE field.
seq = scrambler(zeros(254, 1), ones(7, 1));
assert(isequal(seq(1:127), seq(128:254)), 'scrambler period is not 127');
assert(sum(seq(1:127)) == 64, 'm-sequence must have 64 ones per period');
for p = [1 7 31 63]   % no shorter period
    assert(~isequal(seq(1:127-p), seq(1+p:127)), 'unexpected shorter period');
end
% 802.11 all-ones seed produces 0000 1110 1111 0010 ... (IEEE 802.11 17.3.5.5)
assert(isequal(seq(1:16)', [0 0 0 0 1 1 1 0 1 1 1 1 0 0 1 0]), ...
       'sequence does not match the standard prefix');

bits = double(rand(500, 1) > 0.5);
st = double(rand(7, 1) > 0.5); st(3) = 1;
s1 = scrambler(bits, st);
assert(isequal(scrambler(s1, st), bits), 'descrambling failed');

% receiver recovers the seed from 7 scrambled zero bits
data = [zeros(16, 1); bits];
tx = scrambler(data, st);
rs = scrambler_seed_from_service(tx(1:7));
rx = scrambler(tx(8:end), rs);
assert(isequal(rx, data(8:end)), 'seed recovery from SERVICE failed');

% returned state continues the sequence across calls (streaming)
long = double(rand(300, 1) > 0.5);
[a, st2] = scrambler(long(1:130), st);
b = scrambler(long(131:end), st2);
assert(isequal([a; b], scrambler(long, st)), 'state hand-off between calls broken');
[~, st3] = scrambler(zeros(3, 1), st);           % fewer than 7 bits
full = scrambler(long, st);
assert(isequal(scrambler(long(4:end), st3), full(4:end)), 'short-call state wrong');

threw = false;
try
    scrambler(1, zeros(7, 1));
catch
    threw = true;
end
assert(threw, 'all-zero state must be rejected');
end
