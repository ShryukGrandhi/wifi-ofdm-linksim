function [g0, g1] = conv_generators()
%CONV_GENERATORS  Tap vectors of the 802.11 K=7 code, current input first.
%   133 octal = 1 011 011, 171 octal = 1 111 001.
g0 = [1 0 1 1 0 1 1];
g1 = [1 1 1 1 0 0 1];
end
