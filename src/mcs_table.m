function m = mcs_table(idx)
%MCS_TABLE  802.11a modulation and coding schemes (20 MHz, 48 data subcarriers).
%   m = MCS_TABLE(idx) returns a struct for idx = 1..8. With no argument,
%   returns the number of entries.
%
%   Fields: name, mbps, nbpsc (coded bits per subcarrier), rate ([num den]),
%           ncbps (coded bits per OFDM symbol), ndbps (data bits per symbol).

names = {'BPSK 1/2', 'BPSK 3/4', 'QPSK 1/2', 'QPSK 3/4', ...
         '16QAM 1/2', '16QAM 3/4', '64QAM 2/3', '64QAM 3/4'};
nbpsc = [1 1 2 2 4 4 6 6];
rnum  = [1 3 1 3 1 3 2 3];
rden  = [2 4 2 4 2 4 3 4];
mbps  = [6 9 12 18 24 36 48 54];

if nargin == 0
    m = numel(names);
    return;
end
if idx < 1 || idx > numel(names) || idx ~= floor(idx)
    error('mcs_table:range', 'MCS index must be an integer in 1..%d', numel(names));
end

m.index = idx;
m.name  = names{idx};
m.mbps  = mbps(idx);
m.nbpsc = nbpsc(idx);
m.rate  = [rnum(idx) rden(idx)];
m.ncbps = 48 * nbpsc(idx);
m.ndbps = m.ncbps * rnum(idx) / rden(idx);
end
